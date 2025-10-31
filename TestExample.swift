import ProtocolMirrorMacros

@ProtocolMirror
struct APIClient {
    var fetchUser: (Int) async throws -> String
    var saveUser: (String) async throws -> Void
    var baseURL: String
}

// Test that we can use the protocol
func testProtocol(client: any APIClient.`Protocol`) async throws {
    let user = try await client.fetchUser(42)
    try await client.saveUser(user)
    print("Base URL: \(client.baseURL)")
}

// Test that the original struct conforms
let client = APIClient(
    fetchUser: { id in "User \(id)" },
    saveUser: { name in print("Saving \(name)") },
    baseURL: "https://api.example.com"
)

// This should compile if the macro works
Task {
    try await testProtocol(client: client)
}

print("✅ Macro works! The protocol was generated and the struct conforms to it.")