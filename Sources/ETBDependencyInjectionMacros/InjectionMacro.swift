import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct InjectionMacro: PeerMacro {
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let varDecl = VariableDeclSyntax(declaration) else {
            return []
        }
        
        guard let (name, type, isAny) = getPropertyAttribute(varDecl: varDecl) else {
            return []
        }
        
        let peerDecl: DeclSyntax = {
            if isAny {
                "private var \(raw: name)_Injection: (any \(raw: type))?"
            } else {
                "private var \(raw: name)_Injection: \(raw: type)?"
            }
        }()
        
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
            return []
        }
        
        guard let (name, type, isAny) = getPropertyAttribute(varDecl: varDecl) else {
            return []
        }

        let injectionName = "\(name)_Injection"
        let resolve: DeclSyntax = {
            if isAny {
                "provider?.resolveRequired((any \(raw: type)).self)"
            } else {
                "provider?.resolveRequired(\(raw: type).self)"
            }
        }()
        
        let get: AccessorDeclSyntax = """
            get {
                if \(raw: injectionName) == nil {
                    \(raw: injectionName) = \(raw: resolve)
                }
            
                if let \(raw: injectionName) {
                    return \(raw: injectionName)
                } else {
                    fatalError()
                }
            }
            """
        let set: AccessorDeclSyntax = """
            set {
                \(raw: injectionName) = newValue
            }
            """
        
        return [get, set]
    }
    
}

extension InjectionMacro {
    static func getPropertyAttribute(varDecl: VariableDeclSyntax) -> (name: String, type: String, isAny: Bool)? {
        var name: String = ""
        var isAny: Bool = false
        var type: String = ""
        for binding in varDecl.bindings {
            guard let identifierPattern = IdentifierPatternSyntax(binding.pattern),
                  let identifier = Identifier(identifierPattern.identifier),
                  let typeAnnotation = binding.typeAnnotation else {
                continue
            }
            name = identifier.name
            
            if let someOrAny = SomeOrAnyTypeSyntax(typeAnnotation.type),
               let identifierType = IdentifierTypeSyntax(someOrAny.constraint),
               let identifier = Identifier(identifierType.name) {
                guard someOrAny.someOrAnySpecifier.text == "any" else {
                    // TODO: handle error
                    return nil
                }
                isAny = true
                type = identifier.name
            }
            
            return (name, type, isAny)
        }
        
        return nil
    }
}
