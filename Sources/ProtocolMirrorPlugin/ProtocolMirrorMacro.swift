import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

#if !canImport(SwiftSyntax600)
  import SwiftSyntaxMacroExpansion
#endif

public enum ProtocolMirrorMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      let declType = if declaration.is(ClassDeclSyntax.self) {
        "class"
      } else if declaration.is(EnumDeclSyntax.self) {
        "enum"
      } else if declaration.is(ActorDeclSyntax.self) {
        "actor"
      } else {
        "this declaration"
      }

      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@ProtocolMirror' can only be applied to struct types, but was applied to \(declType). " +
            "Protocol mirroring requires a struct. If you need this for classes, please file an issue at " +
            "https://github.com/coenttb/swift-protocol-mirror/issues"
          )
        )
      )
      return []
    }
    
    let structName = structDecl.name.text
    let access = getAccessLevel(from: structDecl.modifiers)
    
    var protocolMembers: [DeclSyntax] = []
    
    for member in structDecl.memberBlock.members {
      guard let property = member.decl.as(VariableDeclSyntax.self),
            !property.isStatic,
            let binding = property.bindings.first,
            let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
      else { continue }
      
      guard let type = binding.typeAnnotation?.type ?? binding.initializer?.value.literalType else {
        continue
      }
      
      let propertyAccess = getAccessLevel(from: property.modifiers)
      
      if propertyAccess == "private " {
        continue
      }
      
      let isLet = property.bindingSpecifier.tokenKind == .keyword(.let)
      let isClosure = type.is(FunctionTypeSyntax.self)
      let getterOnly = isLet || hasOnlyGetter(binding: binding) || isClosure

      // Add the property requirement
      let accessor = getterOnly ? "{ get }" : "{ get set }"
      let propertyReq: DeclSyntax = "var \(raw: identifier): \(type.trimmed) \(raw: accessor)"
      protocolMembers.append(propertyReq)
      
      // Check for method generation from labeled closures
      if let functionType = type.as(FunctionTypeSyntax.self) {
        var hasLabels = false
        var methodParams: [String] = []

        // Iterate through the function parameters (TupleTypeElementListSyntax)
        for param in functionType.parameters {
          // secondName is the actual parameter label (e.g., "id", "includeDetails")
          // firstName is typically "_" (wildcard) for external parameter names
          if let paramLabel = param.secondName?.text {
            hasLabels = true
            let paramType = param.type.trimmed
            methodParams.append("\(paramLabel): \(paramType)")
          }
        }

        if hasLabels {
          let methodSignature = methodParams.joined(separator: ", ")
          var methodDecl = "func \(identifier)(\(methodSignature))"

          if let effectSpecifiers = functionType.effectSpecifiers {
            if effectSpecifiers.asyncSpecifier != nil {
              methodDecl += " async"
            }
            if effectSpecifiers.throwsClause != nil {
              methodDecl += " throws"
            }
          }

          methodDecl += " -> \(functionType.returnClause.type.trimmed)"

          protocolMembers.append(DeclSyntax(stringLiteral: methodDecl))
        }
      }
    }
    
    guard !protocolMembers.isEmpty else {
      return []
    }
    
    // Create the protocol extension
    let protocolExtension = try ExtensionDeclSyntax(
      "\(raw: access)extension \(raw: structName)"
    ) {
      try ProtocolDeclSyntax("\(raw: access)protocol `Protocol`") {
        for member in protocolMembers {
          member
        }
      }
    }

    // NOTE: Cannot auto-generate conformance due to Swift macro limitation
    // Attempting to create: extension MyStruct: MyStruct.Protocol {}
    // causes "circular reference expanding extension macros" error because
    // the compiler tries to resolve MyStruct.Protocol while still expanding the macro.
    //
    // Users must manually add: extension MyStruct: MyStruct.Protocol {}
    // This is unfortunate but unavoidable with current macro system.

    return [protocolExtension]
  }
}

private extension VariableDeclSyntax {
  var isStatic: Bool {
    self.modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.static)
    }
  }
}

private func getAccessLevel(from modifiers: DeclModifierListSyntax) -> String {
  for modifier in modifiers {
    switch modifier.name.tokenKind {
    case .keyword(.public):
      return "public "
    case .keyword(.package):
      return "package "
    case .keyword(.internal):
      return ""
    case .keyword(.private), .keyword(.fileprivate):
      return "private "
    default:
      continue
    }
  }
  return ""
}

private func hasOnlyGetter(binding: PatternBindingListSyntax.Element) -> Bool {
  guard let accessors = binding.accessorBlock?.accessors else {
    return false
  }
  
  switch accessors {
  case .getter:
    return true
  case let .accessors(list):
    return list.allSatisfy { $0.accessorSpecifier.tokenKind == .keyword(.get) }
  @unknown default:
    return false
  }
}

private extension ExprSyntax {
  var literalType: TypeSyntax? {
    if self.is(BooleanLiteralExprSyntax.self) {
      return "Bool"
    } else if self.is(FloatLiteralExprSyntax.self) {
      return "Double"
    } else if self.is(IntegerLiteralExprSyntax.self) {
      return "Int"
    } else if self.is(StringLiteralExprSyntax.self) {
      return "String"
    } else {
      return nil
    }
  }
}

public struct MacroExpansionErrorMessage: DiagnosticMessage {
  public let message: String
  public let diagnosticID: MessageID
  public let severity: DiagnosticSeverity
  
  public init(_ message: String) {
    self.message = message
    self.diagnosticID = MessageID(domain: "ProtocolMirrorMacro", id: message)
    self.severity = .error
  }
}