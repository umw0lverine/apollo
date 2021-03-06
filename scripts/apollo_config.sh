#! /usr/bin/env bash

###############################################################################
# Copyright 2020 The Apollo Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${TOP_DIR}/cyber/setup.bash"
# STAGE="${STAGE:-dev}"
: ${STAGE:=dev}

IFS='' read -r -d '' STARTUP_TXT << EOF
startup --output_user_root="${APOLLO_CACHE_DIR}/bazel"
common --distdir="${APOLLO_BAZEL_DISTDIR}"
EOF

set -e

BAZEL_CONF="${TOP_DIR}/.apollo.bazelrc"

ARCH="$(uname -m)"

function config_noninteractive() {
  echo "${STARTUP_TXT}" > "${BAZEL_CONF}"
  determine_gpu_use
  if [ "${USE_GPU}" -eq 1 ]; then
    echo "build --config=gpu" >> "${BAZEL_CONF}"
  else
    echo "build --config=cpu" >> "${BAZEL_CONF}"
  fi
  echo -e "build --action_env GCC_HOST_COMPILER_PATH=\"/usr/bin/${ARCH}-linux-gnu-gcc-7\"" >> "${BAZEL_CONF}"
  cat "${TOP_DIR}/tools/apollo.bazelrc.sample" >> "${BAZEL_CONF}"
}

function config_interactive() {
  if [ -z "$PYTHON_BIN_PATH" ]; then
    PYTHON_BIN_PATH=$(which python3 || true)
  fi

  # Set all env variables
  "$PYTHON_BIN_PATH" "${TOP_DIR}/tools/bootstrap.py" "$@"
  echo "${STARTUP_TXT}" >> "${BAZEL_CONF}"
}

function config() {
  local stage="${STAGE}"
  if [ $# -eq 0 ]; then
    config_noninteractive
  else
    local mode="$1"
    shift
    if [ "${mode}" == "--clean" ]; then
      rm -f "${BAZEL_CONF}"
    elif [[ "${mode}" == "--interactive" || "${mode}" == "-i" ]]; then
      config_interactive "$@"
    else
      config_noninteractive
    fi
  fi
}

function main() {
  config "$@"
}

main "$@"
