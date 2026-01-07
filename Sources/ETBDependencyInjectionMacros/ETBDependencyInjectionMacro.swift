import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct ServiceMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = ClassDeclSyntax(declaration) else {
            // TODO: Handle error
            return []
        }
        
        let isClassPublic: Bool = {
            let modifiers = classDecl.modifiers
            if let firstModifier = modifiers.first,
               let declModifier = DeclModifierSyntax(firstModifier),
               declModifier.name.text == "public" {
                return true
            }
            return false
        }()
        
        guard let argumentList = LabeledExprListSyntax(node.arguments),
              let firstArg = argumentList.first,
              let interfaceType = extractType(from: firstArg.expression) else {
            // TODO: Handle error
            return []
        }

        let declarationResult: DeclSyntax
        
        let isTypeAliasAlreadyPresent: Bool = {
            let members = classDecl.memberBlock.members
            return members.contains {
                if let typeAliasDecl = TypeAliasDeclSyntax($0.decl),
                   let identifier = Identifier(typeAliasDecl.name),
                   identifier.name == "Interface" {
                    return true
                }
                return false
            }
        }()
        if !isTypeAliasAlreadyPresent {
            let syntax: String
            if isClassPublic {
                syntax = "public typealias Interface = \(interfaceType)"
            } else {
                syntax = "typealias Interface = \(interfaceType)"
            }
            declarationResult = "\(raw: syntax)"
        } else {
            declarationResult = ""
        }

        return [declarationResult]

        func extractType(from expr: ExprSyntax) -> TypeSyntax? {
            // Pattern like: SomeType.self
            guard let memberAccess = MemberAccessExprSyntax(expr),
                  memberAccess.declName.baseName.text == "self",
                  let base = DeclReferenceExprSyntax(memberAccess.base) else {
                return nil
            }
            return TypeSyntax(IdentifierTypeSyntax(name: base.baseName))
        }
    }
    
}

extension ServiceMacro: ExtensionMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
        var result: [SwiftSyntax.ExtensionDeclSyntax] = []
        
        let mustConformeToService = protocols.contains { proto in
            proto.trimmedDescription == "Service" || proto.trimmedDescription == "ETBDependencyInjection.Service"
        }
        if mustConformeToService {
            let serviceExt: ExtensionDeclSyntax = try ExtensionDeclSyntax("extension \(type): ETBDependencyInjection.Service {}")
            result.append(serviceExt)
        }
        
        return result
    }
    
}

@main
struct ETBDependencyInjectionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ServiceMacro.self,
    ]
}
