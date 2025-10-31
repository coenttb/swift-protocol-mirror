import Testing

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("README patterns compile correctly")
    func readmePatternsCompile() throws {
        // This test verifies that the patterns shown in the README compile
        // Actual macro expansion is tested in ProtocolMirrorTests.swift and ProtocolMirrorMacroTests.swift

        struct User {
            let id: Int
            let name: String
        }

        // Verify basic struct pattern from README
        struct APIClient {
            var fetchUser: (Int) async throws -> User
            var saveUser: (User) async throws -> Void
            var baseURL: String
        }

        let client = APIClient(
            fetchUser: { id in User(id: id, name: "User \(id)") },
            saveUser: { _ in /* no-op */ },
            baseURL: "https://api.example.com"
        )

        #expect(client.baseURL == "https://api.example.com")
    }
}
