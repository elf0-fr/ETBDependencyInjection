import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ETBDependencyInjectionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServiceMacro.self,
        InjectionMacro.self
    ]
}
