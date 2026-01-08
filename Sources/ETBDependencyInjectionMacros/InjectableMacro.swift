import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct InjectableMacro: ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var result: [SwiftSyntax.ExtensionDeclSyntax] = []
        
        let mustConformeToService = protocols.contains { proto in
            proto.trimmedDescription == "Injectable" || proto.trimmedDescription == "ETBDependencyInjection.Injectable"
        }
        if mustConformeToService {
            let serviceExt: ExtensionDeclSyntax = try ExtensionDeclSyntax("extension \(type): ETBDependencyInjection.Injectable {}")
            result.append(serviceExt)
        }
        
        return result
    }
    
}
