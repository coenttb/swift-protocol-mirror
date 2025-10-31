import XCTest
import ProtocolMirrorMacros
import Foundation

// Define test types at module level
@ProtocolMirror
struct TestClient {
  var fetch: () -> String
  var save: (String) -> Void
}
extension TestClient: TestClient.`Protocol` {}

@ProtocolMirror
struct AsyncClient {
  var fetch: () async throws -> Data
}
extension AsyncClient: AsyncClient.`Protocol` {}

final class ProtocolMirrorTests: XCTestCase {
  
  func testProtocolConformance() {
    let client = TestClient(
      fetch: { "test" },
      save: { _ in }
    )
    
    func acceptsProtocol(_ client: any TestClient.`Protocol`) -> String {
      client.fetch()
    }
    
    XCTAssertEqual(acceptsProtocol(client), "test")
  }
  
  func testProtocolWithAsyncThrows() async throws {
    let expectedData = Data([1, 2, 3])
    let client = AsyncClient(
      fetch: { expectedData }
    )
    
    func useClient(_ client: any AsyncClient.`Protocol`) async throws -> Data {
      try await client.fetch()
    }
    
    let data = try await useClient(client)
    XCTAssertEqual(data, expectedData)
  }
}