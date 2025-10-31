# swift-protocol-mirror

[![CI](https://github.com/coenttb/swift-protocol-mirror/workflows/CI/badge.svg)](https://github.com/coenttb/swift-protocol-mirror/actions/workflows/ci.yml)
![Development Status](https://img.shields.io/badge/status-experimental-yellow.svg)

A Swift macro that automatically generates protocols mirroring struct interfaces, enabling protocol-oriented design patterns and improving testability.

## Overview

`@ProtocolMirror` generates a nested protocol that mirrors all the properties of your struct, automatically conforming the struct to this protocol. This is particularly useful for:

- **Dependency Injection**: Define dependencies as protocols instead of concrete types
- **Testing**: Easy creation of test doubles and mocks
- **Modularity**: Swap implementations without changing consumer code
- **API Design**: Cleaner interfaces with protocol constraints

## Installation

Add swift-protocol-mirror to your Package.swift:

```swift
dependencies: [
  .package(url: "https://github.com/coenttb/swift-protocol-mirror", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
.target(
  name: "YourTarget",
  dependencies: [
    .product(name: "ProtocolMirror", package: "swift-protocol-mirror"),
  ]
)
```

## Usage

### Basic Example

```swift
import ProtocolMirror

@ProtocolMirror
struct APIClient {
  var fetchUser: (Int) async throws -> User
  var saveUser: (User) async throws -> Void
  var baseURL: String
}
```

This automatically generates:

```swift
extension APIClient {
  protocol `Protocol` {
    var fetchUser: (Int) async throws -> User { get }
    var saveUser: (User) async throws -> Void { get }
    var baseURL: String { get set }
  }
}
```

Note: You need to manually add the conformance (Swift macro limitation prevents auto-generation):

```swift
extension APIClient: APIClient.`Protocol` {}
```

### Using the Generated Protocol

```swift
// Accept the protocol instead of concrete type
func performWork(client: any APIClient.Protocol) async throws {
  let user = try await client.fetchUser(123)
  try await client.saveUser(user)
}

// Use the original struct (which conforms via manual extension)
let client = APIClient(
  fetchUser: { id in /* ... */ },
  saveUser: { user in /* ... */ },
  baseURL: "https://api.example.com"
)

try await performWork(client: client)
```

### Testing with Protocol

```swift
// Create a mock that conforms to the protocol
struct MockAPIClient: APIClient.Protocol {
  var fetchUser: (Int) async throws -> User {
    { _ in User(id: 1, name: "Test User") }
  }
  
  var saveUser: (User) async throws -> Void {
    { _ in /* no-op for testing */ }
  }
  
  var baseURL: String { "mock://api" }
}

// Use the mock in tests
func testSomething() async throws {
  let mockClient = MockAPIClient()
  try await performWork(client: mockClient)
  // Assert expected behavior
}
```

### Method Generation for Labeled Parameters

When closure properties have labeled parameters, the macro also generates corresponding methods:

```swift
@ProtocolMirror
struct Client {
  var fetch: (_ id: Int, _ includeDetails: Bool) async throws -> User
}

// Generates protocol with both property and method:
protocol `Protocol` {
  var fetch: (_ id: Int, _ includeDetails: Bool) async throws -> User { get }
  func fetch(id: Int, includeDetails: Bool) async throws -> User
}
```

## Features

### Property Types

The macro correctly handles various property types:

- **Closures**: Become get-only protocol requirements
- **Variables (`var`)**: Become get-set requirements
- **Constants (`let`)**: Become get-only requirements  
- **Computed properties**: Become get-only requirements
- **Private properties**: Excluded from the protocol

### Access Control

The generated protocol respects the struct's access level:

```swift
@ProtocolMirror
public struct PublicClient {
  public var endpoint: () -> Void
}

// Generates:
public extension PublicClient {
  public protocol `Protocol` {
    var endpoint: () -> Void { get }
  }
}
```

### Static Members

Static properties and methods are automatically excluded from the generated protocol:

```swift
@ProtocolMirror
struct Service {
  static let shared = Service()  // Excluded
  var instanceMethod: () -> Void // Included
}
```

## Integration with swift-dependencies

This package works excellently with [swift-dependencies](https://github.com/pointfreeco/swift-dependencies):

```swift
import Dependencies
import ProtocolMirror

@ProtocolMirror
@DependencyClient
struct APIClient {
  var fetchUser: (Int) async throws -> User
  var saveUser: (User) async throws -> Void
}

// Now you can use either the concrete type or protocol
extension DependencyValues {
  var apiClient: any APIClient.Protocol {
    get { self[APIClientKey.self] }
    set { self[APIClientKey.self] = newValue }
  }
}
```

## Requirements

- Swift 5.9+
- macOS 10.15+, iOS 13+, tvOS 13+, watchOS 6+

## Experimental Status

This package is marked as **experimental** because:

1. **Point-Free's `@DependencyClient` handles 90% of dependency injection use cases**
2. **Narrow use case** - Manual protocols work fine for most scenarios
3. **Functional but niche** - Works correctly but may not be widely applicable

Consider using [@DependencyClient](https://github.com/pointfreeco/swift-dependencies) for most dependency injection needs. This package is useful when you need protocol mirrors outside the Dependencies framework.

## Related Packages

### Third-Party Dependencies

- [swiftlang/swift-syntax](https://github.com/swiftlang/swift-syntax): Infrastructure for manipulating Swift source code.

## License

Apache 2.0

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

Inspired by the need for better protocol-oriented design patterns in Swift, particularly for dependency injection scenarios.