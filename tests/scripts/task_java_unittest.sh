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

if [ "${TVM_TEST_USE_WHEEL:-0}" = "1" ]; then
    unset PYTHONPATH TVM_LIBRARY_PATH TVM_FFI_LIBRARY_PATH TVM_TIRX_LIBRARY_PATH
    export PYTHONNOUSERSITE=1 TVM_HOME="$PWD"
    uv pip install --python python3 --target .local/python --no-deps apache-tvm-ffi-orcjit==0.1.2
    uv pip install --python python3 --target .local/python --no-deps --offline --reinstall \
        dist/apache_tvm-*.whl dist/apache_tvm_ffi-*.whl dist/apache_tvm_tirx-*.whl
    export PYTHONPATH="$PWD/.local/python"
else
    export PYTHONPATH=tirx/python:python
    export LD_LIBRARY_PATH="lib:${LD_LIBRARY_PATH:-}"
fi

# to avoid CI CPU thread throttling.
export TVM_BIND_THREADS=0
export OMP_NUM_THREADS=1

CURR_DIR=$(cd `dirname $0`; pwd)
SCRIPT_DIR=$CURR_DIR/../../jvm/core/src/test/scripts
TEMP_DIR=$(mktemp -d)

cleanup()
{
  rm -rf "$TEMP_DIR"
}
trap cleanup 0

bash "$(dirname "$0")/task_jvm_build.sh"

# Skip the Java Tests for now
exit 0

# expose tvm runtime lib to system env
export LD_LIBRARY_PATH=$CURR_DIR/../../build/:$LD_LIBRARY_PATH
python "$SCRIPT_DIR"/prepare_test_libs.py "$TEMP_DIR"
JVM_TEST_ARGS="-DskipTests=false -Dtest.tempdir=$TEMP_DIR" \
    bash "$(dirname "$0")/task_jvm_build.sh"
