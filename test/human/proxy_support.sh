#!/bin/bash
set -e

# Scenario test: verify proxy support is installed
source dev-container-features-test-lib

check "human is on PATH" which human
check "human-proxy-setup is on PATH" which human-proxy-setup
check "iptables is installed" which iptables
check "proxy-setup skips when HUMAN_PROXY_ADDR unset" human-proxy-setup

reportResults
