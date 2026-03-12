#!/bin/bash
set -e

# Scenario test: verify a specific version is installed
source dev-container-features-test-lib

check "human is on PATH" which human
check "version contains 0.4.0" bash -c "human --version | grep '0.4.0'"

reportResults
