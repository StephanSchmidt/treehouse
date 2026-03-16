#!/bin/bash
set -e

# Default scenario test: verify human is installed and runs
source dev-container-features-test-lib

check "human is on PATH" which human
check "human --version exits 0" human --version
check "human-browser symlink exists" test -L /usr/local/bin/human-browser
check "human-browser is executable" test -x /usr/local/bin/human-browser
check "BROWSER is set to human-browser" bash -c '[ "$BROWSER" = "human-browser" ]'

reportResults
