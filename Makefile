.PHONY=default compile build stable-environment nightly-environment stable-build nightly-build exec-stable-build exec-nightly-build test exec-test
RUST_STABLE_SPEC="stable"
RUST_NIGHTLY_SPEC="nightly"
CURRENT_USER="$(shell id -u)"
STABLE_IMAGE_NAME="${USER}/rust"
NIGHTLY_IMAGE_NAME="${USER}/rust:nightly"

default: build

build: stable

stable:
	docker build --build-arg USER_ID=$(CURRENT_USER) --build-arg RUST_SPEC=$(RUST_STABLE_SPEC) --tag $(STABLE_IMAGE_NAME) .
nightly:
	docker build --build-arg USER_ID=$(CURRENT_USER) --build-arg RUST_SPEC=$(RUST_NIGHTLY_SPEC) --tag $(NIGHTLY_IMAGE_NAME) .

test:
	$(NIGHTLY_CONTAINER_RUN) make exec-test

exec-test:
	py.test-3 -vv tests

shell:
	docker run --rm -ti $(STABLE_IMAGE_NAME) bash -l
