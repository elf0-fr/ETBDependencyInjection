import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct InjectionMacro: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let varDecl = VariableDeclSyntax(declaration) else {
            let error = Diagnostic.init(
                node: node,
                message: InjectionDiagnostic.notVarDeclaration,
                fixIt: .replace(message: InjectionFixit.notVarDeclaration, oldNode: node, newNode: DeclSyntax(""))
            )
            context.diagnose(error)
            return []
        }
        
        guard let (name, type) = varDecl.getVariableNameAndType() else {
            return []
        }
        
        if OptionalTypeSyntax(type) != nil {
            let optionalError = Diagnostic.init(
                node: node,
                message: InjectionDiagnostic.optionalType
            )
            context.diagnose(optionalError)
            return []
        }
        
        let peerDecl: DeclSyntax =
            """
            private var \(peerInjectionName(from: name)): (\(type))?
            """
        
        return [peerDecl]
    }
    
}

extension InjectionMacro: AccessorMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let varDecl = VariableDeclSyntax(declaration) else {
            let error = Diagnostic.init(
                node: node,
                message: InjectionDiagnostic.notVarDeclaration,
                fixIt: .replace(message: InjectionFixit.notVarDeclaration, oldNode: node, newNode: DeclSyntax(""))
            )
            context.diagnose(error)
            return []
        }
        
        guard let (name, type) = varDecl.getVariableNameAndType() else {
            return []
        }

        let conformToInjectableMacro: Bool = {
            let classDecl = context.lexicalContext.first {
                ClassDeclSyntax($0) != nil
            }
            
            if let classDecl = ClassDeclSyntax(classDecl) {
                return classDecl.attributes.contains {
                    if let attributeSyntax = AttributeSyntax($0),
                       let identifierTypeSyntax = IdentifierTypeSyntax(attributeSyntax.attributeName) {
                        return identifierTypeSyntax.name.text == "Injectable" || identifierTypeSyntax.name.text == "ETBDependencyInjection.Injectable"
                    }
                    return false
                }
            }
            
            return false
        }()
        let injection: TokenSyntax = {
            guard conformToInjectableMacro else { return "" }
                
            return """
            if \(peerInjectionName(from: name)) == nil {
                \(peerInjectionName(from: name)) = provider?.resolveRequired((\(type)).self)
            }
            """
        }()
        
        let get: AccessorDeclSyntax =
            """
            get {
                \(injection)
            
                if let \(peerInjectionName(from: name)) {
                    return \(peerInjectionName(from: name))
                } else {
                    fatalError()
                }
            }
            """
        let set: AccessorDeclSyntax =
            """
            set {
                \(peerInjectionName(from: name)) = newValue
            }
            """
        
        return [get, set]
    }
    
}

extension InjectionMacro {
    
    static func peerInjectionName(from name: IdentifierPatternSyntax) -> TokenSyntax {
        """
        \(name)_Injection
        """
    }
    
    enum InjectionDiagnostic: String, DiagnosticMessage {
        
        case notVarDeclaration
        case optionalType

        var message: String {
            switch self {
            case .notVarDeclaration: "'@Injection' can only be applied to properties."
            case .optionalType: "'@Injection' can only be applied to properties that have a non-optional type."
            }
        }
        
        var severity: DiagnosticSeverity { return .error }
        
        var diagnosticID: MessageID {
            MessageID(domain: "ETBDependencyInjection", id: rawValue)
        }
        
    }
    
    enum InjectionFixit: String, FixItMessage {
        
        case notVarDeclaration

        var message: String {
            switch self {
            case .notVarDeclaration: "Remove: '@Injection'"
            }
        }

        var fixItID: MessageID {
            MessageID(domain: "ETBDependencyInjection", id: rawValue)
        }

    }
    
}

extension VariableDeclSyntax {
    
    func getVariableNameAndType() -> (name: IdentifierPatternSyntax, type: TypeSyntax)? {
        for binding in self.bindings {
            guard let identifierPattern = IdentifierPatternSyntax(binding.pattern),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }
            
            return (identifierPattern, typeAnnotation.type)
        }
        
        return nil
    }
    
}
