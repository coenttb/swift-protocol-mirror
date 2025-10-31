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
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@ProtocolMirror' can only be applied to struct types"
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
      let getterOnly = isLet || hasOnlyGetter(binding: binding)
      
      // Add the property requirement
      let accessor = getterOnly ? "{ get }" : "{ get set }"
      let propertyReq: DeclSyntax = "var \(raw: identifier): \(type.trimmed) \(raw: accessor)"
      protocolMembers.append(propertyReq)
      
      // Check for method generation from labeled closures
      if let functionType = type.as(FunctionTypeSyntax.self) {
        if let parameters = functionType.parameters.first,
           let tupleType = parameters.type.as(TupleTypeSyntax.self) {
          var hasLabels = false
          var methodParams: [String] = []
          
          for element in tupleType.elements {
            if let firstName = element.firstName?.text, firstName != "_" {
              hasLabels = true
              let paramType = element.type.trimmed
              methodParams.append("\(firstName): \(paramType)")
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
    
    // Don't auto-conform due to circular reference issue
    // Users need to manually add: extension MyStruct: MyStruct.Protocol {}
    
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