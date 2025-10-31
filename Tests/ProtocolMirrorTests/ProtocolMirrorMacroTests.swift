import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import ProtocolMirrorPlugin

final class ProtocolMirrorMacroTests: XCTestCase {
  
  func testBasicProtocolGeneration() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct APIClient {
        var fetchUser: (Int) async throws -> User
        var saveUser: (User) async throws -> Void
        var config: Config
      }
      """,
      expandedSource: """
      struct APIClient {
        var fetchUser: (Int) async throws -> User
        var saveUser: (User) async throws -> Void
        var config: Config
      }

      extension APIClient {
          protocol `Protocol` {
              var fetchUser: (Int) async throws -> User {
                  get
              }
              var saveUser: (User) async throws -> Void {
                  get
              }
              var config: Config {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }
}