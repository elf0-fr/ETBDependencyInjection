import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ETBDependencyInjectionMacros)
import ETBDependencyInjectionMacros

let testMacros: [String: Macro.Type] = [
    "Service": ServiceMacro.self,
]
#endif

final class ETBDependencyInjectionTests: XCTestCase {
    func testConformDirectlyToService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyServiceImpl.self)
            class MyServiceImpl: Service {
                required init(provider: any ServiceProvider) {
                    
                }
            }
            """,
            expandedSource: """
            
            class MyServiceImpl: Service {
                required init(provider: any ServiceProvider) {
                    
                }
            
                typealias Interface = MyServiceImpl
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testConformToSubTypeOfService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            protocol MyService: Service {}

            @Service(MyService.self)
            class MyServiceImpl: MyService {
                required init(provider: any ServiceProvider) {
                    
                }
            }
            """,
            expandedSource: """
            protocol MyService: Service {}
            class MyServiceImpl: MyService {
                required init(provider: any ServiceProvider) {
                    
                }
            
                typealias Interface = MyService
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAlreadyConformDirectlyToService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyServiceImpl.self)
            class MyServiceImpl: Service {
                required init(provider: any ServiceProvider) {
                    
                }
            
                typealias Interface = MyServiceImpl
            }
            """,
            expandedSource: """
            
            class MyServiceImpl: Service {
                required init(provider: any ServiceProvider) {
                    
                }
            
                typealias Interface = MyServiceImpl
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testPublicClass() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyServiceImpl.self)
            public class MyServiceImpl: Service {
                public required init(provider: any ServiceProvider) {
                    
                }
            }
            """,
            expandedSource: """
            
            public class MyServiceImpl: Service {
                public required init(provider: any ServiceProvider) {
                    
                }
            
                public typealias Interface = MyServiceImpl
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
