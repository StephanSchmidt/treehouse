#!/bin/bash
set -e

# Default scenario test: verify human is installed and runs
source dev-container-features-test-lib

check "human is on PATH" which human
check "human --version exits 0" human --version

reportResults
