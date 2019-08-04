#!/bin/bash -ex

REQUIRED_SYSTEM_COMMANDS=(
    "kind"
    "kubectl"
    "python3"
    "pip"
    "virtualenv"
)

set +x
for C in ${REQUIRED_SYSTEM_COMMANDS[@]}; do
    if [[ ! -x "$(command -v ${C})" ]]; then
        echo "System command missing: $C"
        exit 1
    fi
done
set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../

# Acceptance test configurables
ROBOT_PY_REQUIRES="${ROBOT_PY_REQUIRES:-robotframework==3.1.2}"
ROBOT_OUTPUT_DIR="${ROBOT_OUTPUT_DIR:-${PWD}/.acceptance}"
ROBOT_HELM_HOME_DIR="${ROBOT_HELM_HOME_DIR:-${ROBOT_OUTPUT_DIR}/.helm}"
ROBOT_VENV_DIR="${ROBOT_VENV_DIR:-${ROBOT_OUTPUT_DIR}/.venv}"
ROBOT_TEST_ROOT_DIR="${ROBOT_TEST_ROOT_DIR:-${PWD}}"

# Setup acceptance test environment:
#
#   - fresh Helm Home at .acceptance/.helm/
#   - Python virtualenv at .acceptance/.venv/ (cached if already fetched)
#
export PATH="${VENV_DIR}/bin:${PATH}"
export HELM_HOME="${ROBOT_HELM_HOME_DIR}"
rm -rf ${HELM_HOME} && mkdir -p ${HELM_HOME}
helm init
if [[ ! -d ${ROBOT_VENV_DIR} ]]; then
    virtualenv -p $(which python3) ${ROBOT_VENV_DIR}
    pip install ${ROBOT_PY_REQUIRES}
fi

# Run Robot Framework, output
robot --outputdir=${ROBOT_OUTPUT_DIR} ${ROBOT_TEST_ROOT_DIR}
