#!/bin/bash

# this script is used to initiate builds regularly

set -e

mkdir -p ~/.docker && echo "${DOCKER_AUTH}" >~/.docker/config.json

set -x


make ci-nightly
make ci-nightly-test
TESTS_PASSED=$?
if [[ $TESTS_PASSED == 0 ]] ; then
  VERSION=$(make get-nightly-version)
  # FIXME: move this to makefile
  docker tag tomastomecek/rust:nightly tomastomecek/rust:$VERSION
  docker push tomastomecek/rust:nightly
  docker push tomastomecek/rust:$VERSION
fi

make ci-stable
make ci-stable-test
TESTS_PASSED=$?
if [[ $TESTS_PASSED == 0 ]] ; then
  VERSION=$(make get-stable-version)
  docker tag tomastomecek/rust tomastomecek/rust:$VERSION
  docker push tomastomecek/rust
  docker push tomastomecek/rust:$VERSION
fi

make ci-clippy
make ci-clippy-test
TESTS_PASSED=$?
if [[ $TESTS_PASSED == 0 ]] ; then
  docker push tomastomecek/rust:clippy
fi
