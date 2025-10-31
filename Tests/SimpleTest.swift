// Simple test to verify macro expansion works
// Run with: swift -Xfrontend -dump-ast Tests/SimpleTest.swift

import ProtocolMirrorMacros

@ProtocolMirror
struct TestClient {
    var fetch: () -> String
}