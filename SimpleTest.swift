import ProtocolMirrorMacros

@ProtocolMirror  
struct TestClient {
    var fetch: () -> String
    var save: (String) -> Void
}

// Manually conform since auto-conformance causes circular reference
extension TestClient: TestClient.`Protocol` {}

// Test usage
func useProtocol(_ client: any TestClient.`Protocol`) {
    let result = client.fetch()
    client.save(result)
    print("✅ Protocol works! Got: \(result)")
}

// Create instance
let client = TestClient(
    fetch: { "Hello from macro!" },
    save: { print("Saving: \($0)") }
)

// Use it
useProtocol(client)
print("✅ Test passed! The macro successfully generated the protocol.")