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

# We force the tests to use a directory of our own choosing
# to make sure that when we wipe it clean, we don't wipe
# some directory that was important to the user.
FINAL_DIR_NAME=".helm_acceptance_tests"

# Acceptance test configurables
ROBOT_PY_REQUIRES="${ROBOT_PY_REQUIRES:-robotframework==3.1.2}"
ROBOT_OUTPUT_DIR="${ROBOT_OUTPUT_DIR:-${PWD}/.acceptance}"
ROBOT_HELM_HOME_DIR="${ROBOT_HELM_HOME_DIR:-${ROBOT_OUTPUT_DIR}}/${FINAL_DIR_NAME}"
ROBOT_VENV_DIR="${ROBOT_VENV_DIR:-${ROBOT_OUTPUT_DIR}/.venv}"
ROBOT_TEST_ROOT_DIR="${ROBOT_TEST_ROOT_DIR:-${PWD}}"

# Allow to specify which test suites to run
ROBOT_RUN_TESTS="${ROBOT_RUN_TESTS:-${ROBOT_TEST_ROOT_DIR}}"
# Allow for a comma-separated list
ROBOT_RUN_TESTS="${ROBOT_RUN_TESTS/,/ }"

# Setup acceptance test environment:
#
#   - fresh Helm Home at .acceptance/.helm/
#   - Python virtualenv at .acceptance/.venv/ (cached if already fetched)
#
if [ ! -z "${ROBOT_HELM_PATH}" ]; then
   export PATH="${ROBOT_HELM_PATH}:${PATH}"
fi
export PATH="${ROBOT_VENV_DIR}/bin:${PATH}"

set +x
# A bit of safety before wiping the entire directory
if [ $(basename ${ROBOT_HELM_HOME_DIR}) == "${FINAL_DIR_NAME}" ]; then
    rm -rf ${ROBOT_HELM_HOME_DIR}
else
    echo "ABORT: should not delete unexpected directory ${ROBOT_HELM_HOME_DIR}"
    echo "ABORT: error in acceptance-testing code!"
    echo "Please report a bug at https://github.com/helm/acceptance-testing/issues"
    exit 1
fi
set -x

export XDG_CACHE_HOME=${ROBOT_HELM_HOME_DIR}/cache && mkdir -p ${XDG_CACHE_HOME}
export XDG_CONFIG_HOME=${ROBOT_HELM_HOME_DIR}/config && mkdir -p ${XDG_CONFIG_HOME}
export XDG_DATA_HOME=${ROBOT_HELM_HOME_DIR}/data && mkdir -p ${XDG_DATA_HOME}

# We fully support helm v3 and partially support helm v2 at this time.
# To figure out which version of helm is used, we run 'helm version'
# with the -c flag which is only supported in helm v2; if we get an
# error, it means we are running helm v3, if we don't get an error,
# it's helm v2. We want to use the -c flag because if
# we end up on helm v2 and we don't have that flag, it will try to
# contact the cluster, which may not be accessible, and the command
# will timeout.
set +x
if helm version -c &> /dev/null; then
    echo "===================="
    echo "Running with Helm v2"
    echo "===================="
    unset ROBOT_HELM_V3
else
    echo "===================="
    echo "Running with Helm v3"
    echo "===================="
    export ROBOT_HELM_V3=1
fi
set -x

if [[ ! -d ${ROBOT_VENV_DIR} ]]; then
    virtualenv -p $(which python3) ${ROBOT_VENV_DIR}
    pip install ${ROBOT_PY_REQUIRES}
fi

# Run Robot Framework, output
robot --outputdir=${ROBOT_OUTPUT_DIR} ${ROBOT_RUN_TESTS}
