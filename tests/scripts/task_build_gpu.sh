#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -euxo pipefail

source ./tests/scripts/task_build_dependencies.sh
export CMAKE_ARGS="
    -DUSE_CUBLAS=ON
    -DUSE_CUDNN=ON
    -DUSE_CUDA=ON
    -DUSE_RPC=ON
    -DUSE_SORT=ON
    -DUSE_BLAS=openblas
    -DCMAKE_CXX_FLAGS=-Werror
    -DUSE_TENSORRT_CODEGEN=ON
    -DHIDE_PRIVATE_SYMBOLS=ON
    -DUSE_CUTLASS=ON
    -DCMAKE_CUDA_ARCHITECTURES=75
    -DUSE_CLML=ON
    -DUSE_CCACHE=OFF
    -DSUMMARIZE=ON
    -DTVM_USE_INSTALLED_TIRX=ON
"
uv build --wheel --no-build-isolation --offline --python python3
