import ProtocolMirrorMacros

@ProtocolMirror
struct APIClient {
  var fetchUser: (Int) async throws -> User
  var saveUser: (User) async throws -> Void
  var baseURL: String
}

struct User {
  let id: Int
  let name: String
}

// Example usage
func performWork(client: any APIClient.Protocol) async throws {
  let user = try await client.fetchUser(42)
  try await client.saveUser(user)
  print("Base URL: \(client.baseURL)")
}

// Create an instance
let client = APIClient(
  fetchUser: { id in User(id: id, name: "User \(id)") },
  saveUser: { user in print("Saving user: \(user.name)") },
  baseURL: "https://api.example.com"
)

// Example of a mock implementation
struct MockAPIClient: APIClient.Protocol {
  var fetchUser: (Int) async throws -> User {
    { id in User(id: id, name: "Mock User") }
  }
  
  var saveUser: (User) async throws -> Void {
    { _ in print("Mock save") }
  }
  
  var baseURL: String { "mock://api" }
}

print("Package swift-protocol-mirror is ready to use!")
print("The @ProtocolMirror macro generates a nested protocol that mirrors your struct.")