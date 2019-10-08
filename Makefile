SHELL = /bin/bash

.PHONY: acceptance
acceptance:
	@scripts/acceptance.sh

.PHONY: github-actions-ci
github-actions-ci:
	@scripts/github-actions-ci.sh

.PHONY: github-actions-ci-local
github-actions-ci-local:
	docker run -it --rm \
	    -v $(shell pwd):/tmp/acceptance-testing \
	    -w /tmp/acceptance-testing  \
	    --privileged -v /var/run/docker.sock:/var/run/docker.sock \
	    --entrypoint=/bin/bash ubuntu:latest \
	    -c 'set +e; scripts/github-actions-ci.sh; echo "Exited $?. (Ctrl+D to exit shell)"; bash'