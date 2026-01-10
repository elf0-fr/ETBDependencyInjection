import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct ServiceMacro: MemberMacro {
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard ClassDeclSyntax(declaration) != nil else {
            let error = Diagnostic.init(
                node: node,
                message: ServiceDiagnostic.notAClass,
                fixIt: .replace(message: ServiceFixit.notAClass, oldNode: node, newNode: DeclSyntax(""))
            )
            context.diagnose(error)
            return []
        }
        
        let isPublic = declaration.modifiers.contains {
            return DeclModifierSyntax($0)?.name.text == "public"
        }
        
        guard let argumentList = LabeledExprListSyntax(node.arguments),
              argumentList.count == 1,
              let firstArg = argumentList.first else {
            let error = Diagnostic.init(
                node: node,
                message: ServiceDiagnostic.wrongNumberOfArguments,
            )
            context.diagnose(error)
            return []
        }
        
        guard let interfaceType = extractType(from: firstArg.expression) else {
            return []
        }

        let isTypeAliasAlreadyPresent: Bool = declaration.memberBlock.members.contains {
            if let typeAliasDecl = TypeAliasDeclSyntax($0.decl),
               let identifier = Identifier(typeAliasDecl.name) {
                return identifier.name == "Interface"
            }
            return false
        }
        
        if !isTypeAliasAlreadyPresent {
            let syntax: DeclSyntax =
            """
                \(raw: isPublic ? "public " : "")typealias Interface = \(interfaceType)   
            """
            return [syntax]
        } else {
            return []
        }

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
        
        let mustConformeToService = protocols.contains {
            $0.trimmedDescription == "Service" || $0.trimmedDescription == "ETBDependencyInjection.Service"
        }
        if mustConformeToService {
            let serviceExt: ExtensionDeclSyntax = try ExtensionDeclSyntax("extension \(type): ETBDependencyInjection.Service {}")
            result.append(serviceExt)
        }
        
        return result
    }
    
}

extension ServiceMacro {
    
    enum ServiceDiagnostic: String, DiagnosticMessage {
        
        case notAClass
        case wrongNumberOfArguments

        var message: String {
            switch self {
            case .notAClass: "'@Service' can only be applied to class types."
            case .wrongNumberOfArguments: "'@Service' accepts only one argument."
            }
        }
        
        var severity: DiagnosticSeverity { return .error }
        
        var diagnosticID: MessageID {
            MessageID(domain: "ETBDependencyInjection", id: rawValue)
        }
        
    }
    
    enum ServiceFixit: String, FixItMessage {
        
        case notAClass

        var message: String {
            switch self {
            case .notAClass: "Remove '@Service'"
            }
        }

        var fixItID: MessageID {
            MessageID(domain: "ETBDependencyInjection", id: rawValue)
        }

    }
}
