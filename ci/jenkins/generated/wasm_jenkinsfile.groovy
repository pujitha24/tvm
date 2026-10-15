// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Reject untrusted helper edits before allocating nodes or running pipeline steps.
def helper_source
try {
  helper_source = readTrusted('ci/jenkins/generated/common.groovy')
} catch (Throwable ex) {
  echo 'Jenkinsfile changes must be pushed to an upstream branch. ' +
    'wasm/pr-head will fail for these changes; check wasm/branch status instead.'
  throw ex
}
ci = evaluate(helper_source)
ci.start()

docker_run += ' --env TVM_TEST_USE_WHEEL=1'

stage('Build') {
  ci.with_node(instance: 'CPU-SPOT', retry_instance: 'CPU',
    name: 'BUILD: WASM', folder: 'tvm/build-wasm', variables: ['PLATFORM=wasm']) {
    ci.docker_init(images.ci_wasm)
    withEnv(ci.build_environment()) {
      sh(
        script: """${docker_run} ${images.ci_wasm} bash -euo pipefail -c '
          rm -rf dist
          uv pip install --python python3 --target build/wheel-build-deps "scikit-build-core>=0.11,!=1.1.0" "setuptools-scm>=8" "cython>=3.2.8"
          PYTHONPATH="\$PWD/build/wheel-build-deps" uv build --wheel --no-build-isolation --offline --python python3 --out-dir dist ./3rdparty/tvm-ffi
          SKBUILD_CMAKE_BUILD_TYPE=RelWithDebInfo SKBUILD_BUILD_DIR="\$PWD/build/tirx-wheel" SKBUILD_BUILD_TARGETS="all;tirx_cpptest" ./tirx/tests/scripts/task_build_cpu.sh
          ./build/tirx-wheel/tirx_cpptest
          SKBUILD_CMAKE_BUILD_TYPE=RelWithDebInfo SKBUILD_BUILD_DIR=build SKBUILD_BUILD_TARGETS="all;cpptest" ./tests/scripts/task_build_wasm.sh
          ./build/cpptest
          sccache --show-stats
        '""",
        label: 'Build wasm wheels and C++ tests',
      )
    }
    sh(
      script: "${docker_run} ${images.ci_wasm} ./tests/scripts/task_web_wasm.sh",
      label: 'Run WASM lint and tests',
    )
  }
}
