# Helm Acceptance Tests

*Note: these tests have only been run against Helm 3 ([dev-v3](https://github.com/helm/helm/tree/dev-v3))*

This repo contains the source for Helm acceptance tests.

The tests are written using [Robot Framework](https://robotframework.org/).

## System requirements

The following tools/commands are expected to be present on the base system
prior to running the tests:

- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [python3](https://www.python.org/downloads/)
- [pip](https://pip.pypa.io/en/stable/installing/)
- [virtualenv](https://virtualenv.pypa.io/en/latest/installation/)

## Running the tests

From the root of this repo, run the following:

```
make acceptance
```

Note: by default, the tests will use helm as found on your PATH.
To specify a different helm to test, set and export the `ROBOT_HELM_PATH`
environment variable.  For example, if you have helm v2 installed, but want
to test helm v3 which is located elsewhere; or if you have helm installed
but want to test a different development version of helm.

### Selecting which test suites to execute

By default `make acceptance` will run every test suite (`*.robot` file) present in the directory specified in the environment variable `ROBOT_TEST_ROOT_DIR`.  You can instead specify which test suites to run by setting and exporting variable `ROBOT_RUN_TESTS`.

For example, to only run the `shells.robot` suite:

```
ROBOT_RUN_TESTS=shells.robot
make acceptance
```

To specify multiple test suites you can set `ROBOT_RUN_TESTS` to a comma-separated, or space-separated list.  For example:

```
ROBOT_RUN_TESTS=shells.robot,kubernetes_versions.robot
make acceptance
```

You can use the list format of `ROBOT_RUN_TESTS` as a way to specify the order in which the test suites should be run.  By default (when `ROBOT_RUN_TESTS` is not specified), the test suites are run in alphabetical order.

## Viewing the results

Robot creates an HTML test report describing test successes/failures.

To view the report, run the following:
####For Mac+Linux:

```
open .acceptance/report.html
```

####For Windows:
```
start chrome .acceptance/report.html
```

Note: by default, the tests will output to the `.acceptance/` directory.
To modify this location, set the `ROBOT_OUTPUT_DIR` environment variable.

## Kubernetes integration

When testing Helm against multiple Kubernetes versions,
new test clusters are created on the fly (using `kind`),
with names in the following format:

```
helm-acceptance-test-<timestamp>-<kube_version>
```

If you wish to use an existing `kind` cluster for one
or more versions, you can set an environment variable for
a given version.

Here is an example of using an existing `kind` cluster
for Kubernetes version `1.15.0`:

```
export KIND_CLUSTER_1_15_0="helm-ac-keepalive-1.15.0"
```

A `kind` cluster can be created manually like so:

```
kind create cluster \
  --name=helm-ac-keepalive-1.15.0 \
  --image=kindest/node:v1.15.0
```

## Adding a new test case etc.

All files ending in `.robot` extension in this directory will be executed.
Add a new file describing your test, or, alternatively, add to an existing one.

Robot tests themselves are written in (mostly) plain English, but the Python
programming language can be used in order to add custom keywords etc.

Notice the [lib/](./lib/) directory - this contains Python libraries that
enable us to work with system tools such as `kind`. The file [common.py](./lib/common.py)
contains a base class called `CommandRunner` that you will likely want to
leverage when adding support for a new external tool.

The test run is wrapped by [acceptance.sh](./scripts/acceptance.sh) -
in this file the environment is validated (i.e. check if required tools present).

sinstalled (including Robot Framework itself). If any additional Python libraries
are required for a new library, it can be appended to `ROBOT_PY_REQUIRES`.
