#!/bin/bash

# this script is used to initiate builds regularly

set -e

mkdir -p ~/.docker && echo "${DOCKER_AUTH}" >~/.docker/config.json

set -x

BUILD_FAILURES=0
LAST_ACTION_PASSED=0

make ci-nightly && make ci-nightly-test || LAST_ACTION_PASSED=$?
if [[ $LAST_ACTION_PASSED == 0 ]] ; then
  VERSION=$(make get-nightly-version)
  # FIXME: move this to makefile
  docker tag tomastomecek/rust:nightly tomastomecek/rust:$VERSION
  docker push tomastomecek/rust:nightly
  docker push tomastomecek/rust:$VERSION
else
  BUILD_FAILURES=$((BUILD_FAILURES+1))
fi

LAST_ACTION_PASSED=0

make ci-stable && make ci-stable-test || LAST_ACTION_PASSED=$?
if [[ $LAST_ACTION_PASSED == 0 ]] ; then
  VERSION=$(make get-stable-version)
  docker tag tomastomecek/rust tomastomecek/rust:$VERSION
  docker push tomastomecek/rust
  docker push tomastomecek/rust:$VERSION
else
  BUILD_FAILURES=$((BUILD_FAILURES+1))
fi

LAST_ACTION_PASSED=0

make ci-clippy && make ci-clippy-test || LAST_ACTION_PASSED=$?
if [[ $LAST_ACTION_PASSED == 0 ]] ; then
  docker push tomastomecek/rust:clippy
else
  BUILD_FAILURES=$((BUILD_FAILURES+1))
fi

exit $BUILD_FAILURES
