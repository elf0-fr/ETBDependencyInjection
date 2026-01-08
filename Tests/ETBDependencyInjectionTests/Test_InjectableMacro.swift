import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacroExpansion
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ETBDependencyInjectionMacros)
import ETBDependencyInjectionMacros

fileprivate let testMacros: [String: Macro.Type] = [
    "Injectable": InjectableMacro.self,
]
fileprivate let macroSpecs: [String: MacroSpec] = [
    "Injectable": MacroSpec(type: InjectableMacro.self, conformances: ["Injectable"])
]
#endif

final class Test_InjectableMacro: XCTestCase {
    func testNotConformingToService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Injectable
            class MyClass {
            }
            """,
            expandedSource: """
            class MyClass {
            }
            
            extension MyClass: ETBDependencyInjection.Injectable {
            }
            """,
            macroSpecs: macroSpecs
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
