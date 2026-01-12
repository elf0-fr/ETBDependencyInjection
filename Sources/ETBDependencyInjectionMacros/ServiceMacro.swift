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
        let isProviderAlreadyPresent: Bool = declaration.memberBlock.members.contains {
            guard let variableDeclSyntax = VariableDeclSyntax($0.decl) else {
                return false
            }
            return variableDeclSyntax.bindings.contains {
                if let identifierPattern = IdentifierPatternSyntax($0.pattern) {
                    return identifierPattern.identifier.text == "provider"
                }
                return false
            }
        }
        let isInitProviderAlreadyPresent: Bool = declaration.memberBlock.members.contains {
            guard let initializerDeclSyntax = InitializerDeclSyntax($0.decl) else {
                return false
            }
            let parameters = initializerDeclSyntax.signature.parameterClause.parameters
            guard parameters.count == 1 else {
                return false
            }
            return parameters.contains {
                $0.firstName.text == "provider"
            }
        }
        
        var result: [DeclSyntax] = []
        let access = declaration.modifiers.first(where: \.isNeededAccessLevelModifier)
        
        if !isTypeAliasAlreadyPresent {
            let syntax: DeclSyntax =
            """
                \(access)typealias Interface = \(interfaceType)   
            """
            result.append(syntax)
        }
        
        if !isProviderAlreadyPresent {
            let syntax: DeclSyntax =
            """
                \(access)var provider: (any ETBDependencyInjection.ServiceProvider)?   
            """
            result.append(syntax)
        }
        
        if !isInitProviderAlreadyPresent {
            let syntax: DeclSyntax =
            """
                \(access)required init(provider: any ETBDependencyInjection.ServiceProvider) {
                    self.provider = provider
                }
            """
            result.append(syntax)
        }
        
        if let builtManualInit = buildManualInit(access: access, members: declaration.memberBlock.members) {
            let isManualInitAlreadyPresent: Bool = declaration.memberBlock.members.contains {
                guard let initializerDeclSyntax = InitializerDeclSyntax($0.decl) else { return false }
                return initializerDeclSyntax.signature.debugDescription == builtManualInit.signature.debugDescription
            }
            if !isManualInitAlreadyPresent {
                result.append(DeclSyntax(builtManualInit))
            }
        }
        
        return result

        func extractType(from expr: ExprSyntax) -> TypeExprSyntax? {
            // Pattern like: SomeType.self
            guard let memberAccess = MemberAccessExprSyntax(expr),
                  let base = memberAccess.base else {
                return nil
            }
            
            if let tuple = TupleExprSyntax(base) {
                let labelExp = tuple.elements.first {
                    return TypeExprSyntax($0.expression) != nil
                }
                if let type = labelExp?.expression {
                    return TypeExprSyntax(type)
                }
            } else if let declRef = DeclReferenceExprSyntax(base) {
                let type = IdentifierTypeSyntax(
                    name: declRef.baseName,
                    genericArgumentClause: nil
                )
                return TypeExprSyntax(type: TypeSyntax(type))
            }
            
            return nil
        }
    }
    
    static func buildManualInit(
        access: DeclModifierListSyntax.Element?,
        members: MemberBlockItemListSyntax
    ) -> InitializerDeclSyntax? {
        let injectedVariables: [(name: IdentifierPatternSyntax, type: TypeSyntax)] = members.compactMap {
            guard let varDecl = VariableDeclSyntax($0.decl),
                  varDecl.attributes.containsInjectionAttribute() else { return nil }
            return varDecl.getVariableNameAndType()
        }
        let arguments = injectedVariables.map { "\($0.name): \($0.type)"}
        let header: SyntaxNodeString =
        """
            \(access)init(\(raw: arguments.joined(separator: ", ")))
        """
        return try? InitializerDeclSyntax(header) {
            for variable in injectedVariables {
                "self.\(variable.name) = \(variable.name)"
            }
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
