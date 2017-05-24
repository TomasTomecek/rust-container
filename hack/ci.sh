#!/bin/bash

# this script is used to initiate builds regularly

set -e

echo $KEY

set -x


make ci-nightly
make ci-nightly-test
TESTS_PASSED=$?
if [[ $TESTS_PASSED == 0 ]] ; then
  VERSION=$(make get-nightly-version)
  docker tag tomastomecek/rust:nightly tomastomecek/rust:$VERSION
  # docker push tomastomecek/rust:nightly
  # docker push tomastomecek/rust:$VERSION
fi

make ci-stable
make ci-stable-test
TESTS_PASSED=$?
if [[ $TESTS_PASSED == 0 ]] ; then
  VERSION=$(make get-stable-version)
  docker tag tomastomecek/rust tomastomecek/rust:$VERSION
  # docker push tomastomecek/rust
  # docker push tomastomecek/rust:$VERSION
fi
