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
    "Injection": InjectionMacro.self,
]
#endif

final class Test_InjectionMacro: XCTestCase {
    func testInjectionWithoutInjectable() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            class MyServiceReader {
                @Injection var service: any Service1
                let name: String
            }
            """,
            expandedSource: """
            class MyServiceReader {
                var service: any Service1 {
                    get {
                        if service_Injection == nil {
                            service_Injection = provider?.resolveRequired((any Service1).self)
                        }

                        if let service_Injection {
                            return service_Injection
                        } else {
                            fatalError()
                        }
                    }
                    set {
                        service_Injection = newValue
                    }
                }

                private var service_Injection: (any Service1)?
                let name: String
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
