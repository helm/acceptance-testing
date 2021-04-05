SHELL    = /bin/bash
ROOT_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: acceptance
acceptance:
	@$(ROOT_DIR)/scripts/acceptance.sh

.PHONY: github-actions-ci
github-actions-ci:
	@$(ROOT_DIR)/scripts/github-actions-ci.sh

.PHONY: github-actions-ci-local
github-actions-ci-local:
	docker run -it --rm \
	    -v $(ROOT_DIR):/tmp/acceptance-testing \
	    -w /tmp/acceptance-testing  \
	    --privileged -v /var/run/docker.sock:/var/run/docker.sock \
	    --entrypoint=/bin/bash ubuntu:latest \
	    -c 'set +e; scripts/github-actions-ci.sh; echo "Exited $?. (Ctrl+D to exit shell)"; bash'

.PHONY: clean
clean:
	/bin/rm -rf $(ROOT_DIR)/.acceptance
