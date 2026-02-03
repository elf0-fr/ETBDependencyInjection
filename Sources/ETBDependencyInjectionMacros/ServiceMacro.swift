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
        
        var result: [DeclSyntax] = []
        let access = declaration.modifiers.first(where: \.isNeededAccessLevelModifier)
       
        if let builtTypeAlias = buildTypeAlias(access: access, type: interfaceType) {
            let isAlreadyPresent: Bool = declaration.memberBlock.members.contains {
                guard let typeAliasDecl = TypeAliasDeclSyntax($0.decl),
                   let identifier = Identifier(typeAliasDecl.name) else {
                    return false
                }
                return identifier.name == "Interface"
            }
            if !isAlreadyPresent {
                result.append(DeclSyntax(builtTypeAlias))
            }
        }
        
        if let builtVar = buildProviderVariable(access: access) {
            let isAlreadyPresent: Bool = declaration.memberBlock.members.contains {
                guard let variableDeclSyntax = VariableDeclSyntax($0.decl),
                      variableDeclSyntax.bindingSpecifier.tokenKind == .keyword(.var),
                      variableDeclSyntax.bindings.count == 1,
                      let binding = variableDeclSyntax.bindings.first else { return false }
                guard let pattern = PatternBindingSyntax(binding) else { return false }
                let variableTrimmedDescription = "var \(PatternBindingSyntax(pattern: pattern.pattern, typeAnnotation: pattern.typeAnnotation).trimmedDescription)"
                return variableTrimmedDescription == "var provider: (any ServiceProvider)?"
                || variableTrimmedDescription == "var provider: (any ETBDependencyInjection.ServiceProvider)?"
            }
            if !isAlreadyPresent {
                result.append(DeclSyntax(builtVar))
            }
        }
        
        if let builtInit = buildInitWithProviderParameter(access: access) {
            let isAlreadyPresent: Bool = declaration.memberBlock.members.contains {
                guard let initializerDeclSyntax = InitializerDeclSyntax($0.decl) else { return false }
                let signatureTrimmedDescription = initializerDeclSyntax.signature.trimmedDescription
                return signatureTrimmedDescription == "(provider: any ServiceProvider)"
                || signatureTrimmedDescription == "(provider: any ETBDependencyInjection.ServiceProvider)"
            }
            if !isAlreadyPresent {
                result.append(DeclSyntax(builtInit))
            }
        }
        
        if let builtInit = buildManualInit(access: access, members: declaration.memberBlock.members) {
            let isAlreadyPresent: Bool = declaration.memberBlock.members.contains {
                guard let initializerDeclSyntax = InitializerDeclSyntax($0.decl) else { return false }
                return initializerDeclSyntax.signature.trimmedDescription == builtInit.signature.trimmedDescription
            }
            if !isAlreadyPresent {
                result.append(DeclSyntax(builtInit))
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
    
    static func buildTypeAlias(access: DeclModifierListSyntax.Element?, type: TypeExprSyntax) -> TypeAliasDeclSyntax? {
        let modifiers: DeclModifierListSyntax = {
            guard let access else { return [] }
            return DeclModifierListSyntax { access }
        }()
        return TypeAliasDeclSyntax(
            modifiers: modifiers,
            name: .identifier("Interface"),
            initializer: .init(value: type.type)
        )
    }
    
    static func buildProviderVariable(access: DeclModifierListSyntax.Element?) -> VariableDeclSyntax? {
        let header: SyntaxNodeString =
        """
            \(access)var provider: (any ETBDependencyInjection.ServiceProvider)?   
        """
        return try? VariableDeclSyntax(header)
    }
    
    static func buildInitWithProviderParameter(access: DeclModifierListSyntax.Element?) -> InitializerDeclSyntax? {
        let header: SyntaxNodeString =
        """
            \(access)required init(provider: any ETBDependencyInjection.ServiceProvider)
        """
        return try? InitializerDeclSyntax(header) {
            "self.provider = provider"
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
        
        let arguments = injectedVariables.map { "\($0.name.trimmedDescription): \($0.type.trimmedDescription)"}
        let header: SyntaxNodeString =
        """
            \(access)init(\(raw: arguments.joined(separator: ", ")))
        """
        return try? InitializerDeclSyntax(header) {
            for variable in injectedVariables {
                "self.\(raw: variable.name.trimmedDescription) = \(raw: variable.name.trimmedDescription)"
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
