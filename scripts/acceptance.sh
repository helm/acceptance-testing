#!/bin/bash -e

# Turn on debug printouts if the user requested a debug level >= $1
set_shell_debug_level()
{
    set +x
    if [ $ROBOT_DEBUG_LEVEL -ge $1 ]; then
       set -x
    fi
}
export -f set_shell_debug_level

export ROBOT_DEBUG_LEVEL="${ROBOT_DEBUG_LEVEL:-0}"
if [ ${ROBOT_DEBUG_LEVEL} -lt 0 ] || [ ${ROBOT_DEBUG_LEVEL} -gt 3 ]; then
   echo "If set, ROBOT_DEBUG_LEVEL must be between 0 and 3."
   echo "0 - None, 1 - Low, 2 - Medium, 3 - High"
   echo "Currently ROBOT_DEBUG_LEVEL=${ROBOT_DEBUG_LEVEL}"
   exit 1
fi

set_shell_debug_level 2
REQUIRED_SYSTEM_COMMANDS=(
    "kind"
    "kubectl"
    "python3"
    "pip"
    "virtualenv"
)

set_shell_debug_level 3
for C in ${REQUIRED_SYSTEM_COMMANDS[@]}; do
    if [[ ! -x "$(command -v ${C})" ]]; then
        echo "System command missing: $C"
        exit 1
    fi
done

set_shell_debug_level 2
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../

# Acceptance test configurables
ROBOT_PY_REQUIRES="${ROBOT_PY_REQUIRES:-robotframework==3.1.2}"
export ROBOT_OUTPUT_DIR="${ROBOT_OUTPUT_DIR:-${PWD}/.acceptance}"
ROBOT_VENV_DIR="${ROBOT_VENV_DIR:-${ROBOT_OUTPUT_DIR}/.venv}"

# Only use the -d flag for mktemp as many other flags don't
# work on every plateform
export TMP_DIR=$(mktemp -d ${ROBOT_OUTPUT_DIR}/helm-acceptance.XXXXXX)
trap "rm -rf ${TMP_DIR}" EXIT

SUITES_TO_RUN=""
# Allow to specify which test suites to run in a space-separated or comma-separated list
for suite in ${ROBOT_RUN_TESTS/,/ }; do
   SUITES_TO_RUN+="testsuites/${suite} "
done
# If no suites was specified, default to all
SUITES_TO_RUN=${SUITES_TO_RUN:-testsuites}

# Setup acceptance test environment:
#
#   - fresh Helm Home at .acceptance/.helm/
#   - Python virtualenv at .acceptance/.venv/ (cached if already fetched)
#
if [ ! -z "${ROBOT_HELM_PATH}" ]; then
   export PATH="${ROBOT_HELM_PATH}:${PATH}"
fi
export PATH="${ROBOT_VENV_DIR}/bin:${PATH}"

export XDG_CACHE_HOME=${TMP_DIR}/cache && mkdir -p ${XDG_CACHE_HOME}
export XDG_CONFIG_HOME=${TMP_DIR}/config && mkdir -p ${XDG_CONFIG_HOME}
export XDG_DATA_HOME=${TMP_DIR}/data && mkdir -p ${XDG_DATA_HOME}

# We fully support helm v3 and partially support helm v2 at this time.
# To figure out which version of helm is used, we run 'helm version'
# with the -c flag which is only supported in helm v2; if we get an
# error, it means we are running helm v3, if we don't get an error,
# it's helm v2. We want to use the -c flag because if
# we end up on helm v2 and we don't have that flag, it will try to
# contact the cluster, which may not be accessible, and the command
# will timeout.
set_shell_debug_level 3
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

set_shell_debug_level 2
if [[ ! -d ${ROBOT_VENV_DIR} ]]; then
    virtualenv -p $(which python3) ${ROBOT_VENV_DIR}
    pip install ${ROBOT_PY_REQUIRES}
fi

# Run Robot Framework, output
robot --outputdir=${ROBOT_OUTPUT_DIR} ${SUITES_TO_RUN}
