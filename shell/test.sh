#!/usr/bin/env bash
# Run the OmacosCore tests (Swift Testing) and the vendored vim engine's harness.
# The Swift Build engine finds the Command Line Tools' Testing macro plugin only on a clean
# build, so incremental `swift test` failed with "plugin for module 'TestingMacros' not found";
# naming the plugin directory explicitly works every time.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
plugins="$(dirname "$(xcrun --find swift)")/../lib/swift/host/plugins/testing"
swift test -Xswiftc -plugin-path -Xswiftc "$plugins" "$@"
swift run VimEngineTests | tail -1
