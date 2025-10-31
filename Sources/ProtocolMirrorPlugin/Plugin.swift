import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ProtocolMirrorPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ProtocolMirrorMacro.self,
  ]
}