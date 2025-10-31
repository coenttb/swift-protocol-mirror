import Testing
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import ProtocolMirrorPlugin

@Suite("Protocol Mirror Macro Tests")
struct ProtocolMirrorMacroTests {

  @Test("Basic protocol generation")
  func basicProtocolGeneration() {
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

  // MARK: - Access Control Tests

  @Test("Public access control")
  func publicAccessControl() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      public struct PublicClient {
        public var endpoint: String
      }
      """,
      expandedSource: """
      public struct PublicClient {
        public var endpoint: String
      }

      public extension PublicClient {
          public protocol `Protocol` {
              var endpoint: String {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Package access control")
  func packageAccessControl() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      package struct PackageClient {
        package var endpoint: String
      }
      """,
      expandedSource: """
      package struct PackageClient {
        package var endpoint: String
      }

      package extension PackageClient {
          package protocol `Protocol` {
              var endpoint: String {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Private properties excluded")
  func privatePropertiesExcluded() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Client {
        var publicProp: String
        private var privateProp: Int
      }
      """,
      expandedSource: """
      struct Client {
        var publicProp: String
        private var privateProp: Int
      }

      extension Client {
          protocol `Protocol` {
              var publicProp: String {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  // MARK: - Property Type Tests

  @Test("Let properties are get-only")
  func letPropertiesAreGetOnly() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Config {
        let constantValue: String
        var mutableValue: Int
      }
      """,
      expandedSource: """
      struct Config {
        let constantValue: String
        var mutableValue: Int
      }

      extension Config {
          protocol `Protocol` {
              var constantValue: String {
                  get
              }
              var mutableValue: Int {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Computed properties with getter only")
  func computedPropertiesWithGetterOnly() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Service {
        var computed: String { "value" }
        var mutable: Int
      }
      """,
      expandedSource: """
      struct Service {
        var computed: String { "value" }
        var mutable: Int
      }

      extension Service {
          protocol `Protocol` {
              var computed: String {
                  get
              }
              var mutable: Int {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  // MARK: - Static Property Tests

  @Test("Static properties excluded")
  func staticPropertiesExcluded() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Service {
        static let shared = Service()
        var instanceProperty: String
      }
      """,
      expandedSource: """
      struct Service {
        static let shared = Service()
        var instanceProperty: String
      }

      extension Service {
          protocol `Protocol` {
              var instanceProperty: String {
                  get
                  set
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  // MARK: - Method Generation Tests

  @Test("Labeled closure generates method")
  func labeledClosureGeneratesMethod() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Client {
        var fetch: (_ id: Int, _ includeDetails: Bool) async throws -> User
      }
      """,
      expandedSource: """
      struct Client {
        var fetch: (_ id: Int, _ includeDetails: Bool) async throws -> User
      }

      extension Client {
          protocol `Protocol` {
              var fetch: (_ id: Int, _ includeDetails: Bool) async throws -> User {
                  get
              }
              func fetch(id: Int, includeDetails: Bool) async throws -> User
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Unlabeled closure does not generate method")
  func unlabeledClosureDoesNotGenerateMethod() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct Client {
        var fetch: (Int, Bool) -> User
      }
      """,
      expandedSource: """
      struct Client {
        var fetch: (Int, Bool) -> User
      }

      extension Client {
          protocol `Protocol` {
              var fetch: (Int, Bool) -> User {
                  get
              }
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Method generation with async throws")
  func methodGenerationWithAsyncThrows() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct AsyncClient {
        var fetch: (_ id: Int) async throws -> Data
      }
      """,
      expandedSource: """
      struct AsyncClient {
        var fetch: (_ id: Int) async throws -> Data
      }

      extension AsyncClient {
          protocol `Protocol` {
              var fetch: (_ id: Int) async throws -> Data {
                  get
              }
              func fetch(id: Int) async throws -> Data
          }
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  // MARK: - Error Case Tests

  @Test("Error when applied to class")
  func errorWhenAppliedToClass() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      class MyClass {
        var property: String
      }
      """,
      expandedSource: """
      class MyClass {
        var property: String
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@ProtocolMirror' can only be applied to struct types, but was applied to class. Protocol mirroring requires a struct. If you need this for classes, please file an issue at https://github.com/coenttb/swift-protocol-mirror/issues",
          line: 1,
          column: 1
        )
      ],
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Error when applied to enum")
  func errorWhenAppliedToEnum() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      enum MyEnum {
        case value
      }
      """,
      expandedSource: """
      enum MyEnum {
        case value
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@ProtocolMirror' can only be applied to struct types, but was applied to enum. Protocol mirroring requires a struct. If you need this for classes, please file an issue at https://github.com/coenttb/swift-protocol-mirror/issues",
          line: 1,
          column: 1
        )
      ],
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Error when applied to actor")
  func errorWhenAppliedToActor() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      actor MyActor {
        var property: String
      }
      """,
      expandedSource: """
      actor MyActor {
        var property: String
      }
      """,
      diagnostics: [
        DiagnosticSpec(
          message: "'@ProtocolMirror' can only be applied to struct types, but was applied to actor. Protocol mirroring requires a struct. If you need this for classes, please file an issue at https://github.com/coenttb/swift-protocol-mirror/issues",
          line: 1,
          column: 1
        )
      ],
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  // MARK: - Edge Case Tests

  @Test("Empty struct generates no protocol")
  func emptyStructGeneratesNoProtocol() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct EmptyStruct {
      }
      """,
      expandedSource: """
      struct EmptyStruct {
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Struct with only static properties generates no protocol")
  func structWithOnlyStaticPropertiesGeneratesNoProtocol() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct StaticOnly {
        static let shared = StaticOnly()
        static var config = "default"
      }
      """,
      expandedSource: """
      struct StaticOnly {
        static let shared = StaticOnly()
        static var config = "default"
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }

  @Test("Struct with only private properties generates no protocol")
  func structWithOnlyPrivatePropertiesGeneratesNoProtocol() {
    assertMacroExpansion(
      """
      @ProtocolMirror
      struct PrivateOnly {
        private var secret: String
        private let hidden: Int
      }
      """,
      expandedSource: """
      struct PrivateOnly {
        private var secret: String
        private let hidden: Int
      }
      """,
      macros: ["ProtocolMirror": ProtocolMirrorMacro.self]
    )
  }
}