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

                public var provider: (any ETBDependencyInjection.ServiceProvider)?
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

                var provider: (any ETBDependencyInjection.ServiceProvider)?
            }

            extension MyServiceImpl: ETBDependencyInjection.Service {
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: ["Service"])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAlreadyConformingToService() throws {
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

                var provider: (any ETBDependencyInjection.ServiceProvider)?
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: [])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testTypeAsArgument() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service(MyService.self)
            class MyServiceImpl {
            }
            """,
            expandedSource: """
            
            class MyServiceImpl {

                typealias Interface = MyService

                var provider: (any ETBDependencyInjection.ServiceProvider)?
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: [])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testAnyTypeAsArgument() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service((any MyService).self)
            class MyServiceImpl {
            }
            """,
            expandedSource: """
            
            class MyServiceImpl {

                typealias Interface = any MyService

                var provider: (any ETBDependencyInjection.ServiceProvider)?
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: [])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testTypealiasAlreadyPresent() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service((any MyService).self)
            class MyServiceImpl {
                typealias Interface = any MyService
            }
            """,
            expandedSource: """
            
            class MyServiceImpl {
                typealias Interface = any MyService

                var provider: (any ETBDependencyInjection.ServiceProvider)?
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: [])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testProviderAlreadyPresent() throws {
        #if canImport(ETBDependencyInjectionMacros)
        assertMacroExpansion(
            """
            @Service((any MyService).self)
            class MyServiceImpl {
                var provider: (any ServiceProvider)?
            }
            """,
            expandedSource: """
            class MyServiceImpl {
                var provider: (any ServiceProvider)?
            
                typealias Interface = any MyService
            }
            """,
            macroSpecs: ["Service": MacroSpec(type: ServiceMacro.self, conformances: [])]
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
