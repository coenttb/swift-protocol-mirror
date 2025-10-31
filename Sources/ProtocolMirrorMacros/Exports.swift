/// Generates a protocol that mirrors the properties of a struct.
///
/// This macro automatically creates a nested protocol within your struct that contains
/// all the public properties as protocol requirements, and makes the struct conform to it.
///
/// ## Usage
///
/// Apply the `@ProtocolMirror` macro to any struct:
///
/// ```swift
/// @ProtocolMirror
/// struct APIClient {
///   var fetchUser: (Int) async throws -> User
///   var saveUser: (User) async throws -> Void
///   var config: Config
/// }
/// ```
///
/// This generates:
///
/// ```swift
/// extension APIClient {
///   protocol `Protocol` {
///     var fetchUser: (Int) async throws -> User { get }
///     var saveUser: (User) async throws -> Void { get }
///     var config: Config { get set }
///   }
/// }
///
/// extension APIClient: APIClient.`Protocol` {}
/// ```
///
/// Now you can use `APIClient.Protocol` as a type:
///
/// ```swift
/// func performWork(client: any APIClient.Protocol) async throws {
///   let user = try await client.fetchUser(42)
///   // ...
/// }
/// ```
///
/// ## Features
///
/// - **Automatic protocol generation**: Creates a nested `Protocol` type with all properties
/// - **Automatic conformance**: The struct automatically conforms to the generated protocol
/// - **Closure support**: Closure properties become get-only requirements
/// - **Method generation**: If closures have labeled parameters, corresponding methods are generated
/// - **Access control**: Respects property visibility (private properties are excluded)
/// - **Property mutability**: Correctly handles `let` vs `var` and computed properties
///
/// ## Notes
///
/// The protocol is named `Protocol` (with backticks since it's a reserved word).
/// You can reference it as `YourStruct.Protocol` in your code.
@attached(extension, names: arbitrary)
public macro ProtocolMirror() = #externalMacro(
  module: "ProtocolMirrorPlugin",
  type: "ProtocolMirrorMacro"
)