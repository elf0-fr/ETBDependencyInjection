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
            }
            """,
            expandedSource: """
            class MyServiceReader {
                var service: any Service1 {
                    get {


                        if let _injection_service {
                            return _injection_service
                        } else {
                            fatalError()
                        }
                    }
                    set {
                        _injection_service = newValue
                    }
                }

                private var _injection_service: (any Service1)?
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testInjectionWithInjectableMacro() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Injectable
            class MyServiceReader {
                @Injection var service: any Service1
            }
            """,
            expandedSource: """
            @Injectable
            class MyServiceReader {
                var service: any Service1 {
                    get {
                        if _injection_service == nil {
                        _injection_service = provider?.resolveRequired((any Service1).self)
                        }

                        if let _injection_service {
                            return _injection_service
                        } else {
                            fatalError()
                        }
                    }
                    set {
                        _injection_service = newValue
                    }
                }

                private var _injection_service: (any Service1)?
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
