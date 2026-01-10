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
    "Service": ServiceMacro.self,
]
fileprivate let macroSpecs: [String: MacroSpec] = [
    "Service": MacroSpec(type: ServiceMacro.self, conformances: ["Service"])
]
#endif

final class Test_ServiceMacro: XCTestCase {
    func testConformDirectlyToService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyServiceImpl.self)
            class MyServiceImpl: Service {
            }
            """,
            expandedSource: """
            
            class MyServiceImpl: Service {
            
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
            }
            """,
            expandedSource: """
            protocol MyService: Service {}
            class MyServiceImpl: MyService {
            
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
                typealias Interface = MyServiceImpl
            }
            """,
            expandedSource: """
            
            class MyServiceImpl: Service {
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
            }
            """,
            expandedSource: """
            
            public class MyServiceImpl: Service {
            
                public typealias Interface = MyServiceImpl
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testNotConformingToService() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyServiceImpl.self)
            class MyServiceImpl {
            }
            """,
            expandedSource: """
            class MyServiceImpl {
            
                typealias Interface = MyServiceImpl
            }
            
            extension MyServiceImpl: ETBDependencyInjection.Service {
            }
            """,
            macroSpecs: macroSpecs
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
