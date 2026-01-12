import SwiftSyntax

extension DeclModifierSyntax {
    
    var isNeededAccessLevelModifier: Bool {
        switch self.name.tokenKind {
        case .keyword(.public): return true
        default: return false
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

extension AttributeListSyntax {
    
    func containsInjectionAttribute() -> Bool {
        let injection: AttributeSyntax = "@Injection"
        let injectionDescription = injection.debugDescription
        let ETBDependencyInjection: AttributeSyntax = "@ETBDependencyInjection.Injection"
        let ETBDependencyInjectionDescription = ETBDependencyInjection.debugDescription

        return self.contains {
            let description = $0.debugDescription
            return description == injectionDescription || description == ETBDependencyInjectionDescription
        }
        
    }
    
}
