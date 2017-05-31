.PHONY=default build stable nightly ci-stable ci-nightly ci-nightly-test ci-stable-test shell get-stable-version get-nightly-version
RUST_STABLE_SPEC="stable"
RUST_NIGHTLY_SPEC="nightly"
CURRENT_USER_ID="$(shell id -u)"
CI_USER_ID="1000"
STABLE_IMAGE_NAME="${USER}/rust"
NIGHTLY_IMAGE_NAME="${USER}/rust:nightly"
CLIPPY_IMAGE_NAME="${USER}/rust:clippy"
CI_STABLE_IMAGE_NAME="tomastomecek/rust"
CI_NIGHTLY_IMAGE_NAME="tomastomecek/rust:nightly"
CI_CLIPPY_IMAGE_NAME="tomastomecek/rust:clippy"

default: build

build: stable

stable:
	docker build --build-arg USER_ID=$(CURRENT_USER_ID) --build-arg RUST_SPEC=$(RUST_STABLE_SPEC) --tag $(STABLE_IMAGE_NAME) .
nightly:
	docker build --build-arg USER_ID=$(CURRENT_USER_ID) --build-arg RUST_SPEC=$(RUST_NIGHTLY_SPEC) --tag $(NIGHTLY_IMAGE_NAME) .
clippy:
	docker build --build-arg USER_ID=$(CURRENT_USER_ID) --build-arg RUST_SPEC=$(RUST_NIGHTLY_SPEC) --build-arg WITH_CLIPPY=yes --tag $(CLIPPY_IMAGE_NAME) .

ci-stable:
	docker build --build-arg USER_ID=$(CI_USER_ID) --build-arg RUST_SPEC=$(RUST_STABLE_SPEC) --tag $(CI_STABLE_IMAGE_NAME) .
ci-nightly:
	docker build --build-arg USER_ID=$(CI_USER_ID) --build-arg RUST_SPEC=$(RUST_NIGHTLY_SPEC) --tag $(CI_NIGHTLY_IMAGE_NAME) .
ci-clippy:
	docker build --build-arg USER_ID=$(CI_USER_ID) --build-arg RUST_SPEC=$(RUST_NIGHTLY_SPEC) --build-arg WITH_CLIPPY=yes --tag $(CI_CLIPPY_IMAGE_NAME) .

# TODO: run tests in container
# test:
# 	$(NIGHTLY_CONTAINER_RUN) make exec-test

ci-nightly-test:
	IMAGE_NAME=$(CI_NIGHTLY_IMAGE_NAME) py.test -vv -m "generic and not clippy" tests
ci-stable-test:
	IMAGE_NAME=$(CI_STABLE_IMAGE_NAME) py.test -vv -m "generic and not clippy" tests
ci-clippy-test:
	IMAGE_NAME=$(CI_CLIPPY_IMAGE_NAME) py.test -vv -m 'generic or clippy' tests

# needs to be called as `make --no-print-directory test-ci-script`
test-ci-script:
	DONT_PUSH=yes hack/ci.sh

shell:
	docker run --rm -ti $(STABLE_IMAGE_NAME) bash -l

get-stable-version:
	@docker run --rm -ti $(CI_STABLE_IMAGE_NAME) rustc -V | awk '{ print $$2 }'

get-nightly-version:
	@docker run --rm -ti $(CI_NIGHTLY_IMAGE_NAME) rustc -V | awk '{ print $$2 }'
