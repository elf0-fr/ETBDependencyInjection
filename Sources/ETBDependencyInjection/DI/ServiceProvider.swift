
/// A lightweight abstraction for resolving dependencies from a service container.
///
/// ServiceProvider defines the minimal interface needed to obtain instances of services
/// that have been registered elsewhere in your application. It supports both optional
/// resolution—allowing callers to handle missing services gracefully—and a required
/// variant that enforces the presence of a dependency at runtime.
///
/// Typical usage involves passing a ServiceProvider into features or components that
/// need to look up their dependencies without knowing about the concrete container
/// implementation. This promotes testability and modular design, since test doubles
/// can implement the same protocol.
///
/// Conforming types are expected to manage service lifecycles according to their own
/// policies (e.g., singleton, scoped, or transient). The protocol does not prescribe
/// how services are registered or stored—only how they are retrieved.
///
/// - Important: Prefer `resolveRequired(_:)` when a missing service indicates a
///   programmer error or misconfiguration. Use `resolve(_:)` when absence is a valid
///   outcome that the caller can handle.
///
/// Example:
/// ```swift
/// let logger: Logger = provider.resolveRequired(Logger.self)
/// let metrics = provider.resolve(Metrics.self) // Optional
/// ```
public protocol ServiceProvider {
    
    /// Resolves and returns an instance that conforms to the requested service type.
    ///
    /// Use this method to retrieve an optional instance of a service previously registered
    /// with the service container. If no matching service is found, the method returns `nil`
    /// instead of throwing, allowing callers to handle absence gracefully.
    ///
    /// - Parameter serviceType: The metatype of the service to resolve (e.g., `MyService.self`).
    /// - Returns: An instance conforming to `Service` if one is registered and available; otherwise, `nil`.
    /// - Note: Prefer `resolveRequired(_:)` when the service is expected to be present and its absence is a programming error.
    func resolve<Service>(_ serviceType: Service.Type) -> Service?
    
    /// Resolves an optional instance of a service by its interface type and casts it to a specific implementation.
    ///
    /// This method allows you to retrieve a service that was registered under an interface (such as a protocol)
    /// and obtain it as a concrete implementation type. This is useful when you need access to implementation-specific
    /// functionality that isn't exposed through the interface, or when working with multiple implementations of
    /// the same interface.
    ///
    /// The method performs a runtime cast from the resolved interface to the requested implementation type.
    /// If the service is not registered, or if the registered service cannot be cast to the implementation type,
    /// the method returns `nil`.
    ///
    /// - Parameters:
    ///   - interfaceType: The metatype of the interface under which the service was registered (e.g., `UserServiceInterface.self`).
    ///     Defaults to `Implementation.Interface.self` if not specified.
    ///   - implementationType: The concrete implementation type to cast the resolved service to (e.g., `UserService.self`).
    /// - Returns: An instance of the concrete implementation if the service is registered and the cast succeeds; otherwise, `nil`.
    ///
    /// - Note: This method is provided as a convenience for scenarios where you need the concrete type rather than
    ///   the interface. In most cases, prefer resolving by interface alone using `resolve(_:)` to maintain loose coupling.
    ///   This method is particularly useful in SwiftUI previews, where you may want to resolve a service
    ///   that has been registered with a mock implementation, allowing you to retrieve the mock directly
    ///   for additional configuration or verification.
    ///
    /// Example:
    /// ```swift
    /// // Resolve as a specific implementation
    /// let concreteService = provider.resolve(as: UserService.self)
    ///
    /// // Or explicitly specify the interface
    /// let explicitService = provider.resolve(UserServiceInterface.self, as: UserService.self)
    /// ```
    ///
    /// - SeeAlso: ``resolveRequired(_:as:)`` for a non-optional variant that enforces the presence of the service.
    func resolve<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type,
        as implementationType: Implementation.Type
    ) -> Implementation? where Interface.Type == Implementation.Interface.Type
    
    /// Resolves and returns an instance that conforms to the requested service type, or
    /// triggers a runtime failure if no such service is registered.
    ///
    /// Use this method when the presence of the service is mandatory and its absence
    /// indicates a programming error or misconfiguration. Unlike `resolve(_:)`, which
    /// returns `nil` when a service cannot be found, this variant enforces the contract
    /// that the service must exist, allowing clients to avoid optional handling and
    /// surface configuration issues early.
    ///
    /// - Parameter serviceType: The metatype of the service to resolve (e.g., `MyService.self`).
    /// - Returns: An instance conforming to `Service` that has been previously registered and is available.
    /// - Precondition: A matching service must be registered and resolvable. Implementations are expected
    ///   to trap (e.g., via `preconditionFailure` or `fatalError`) if the service cannot be found.
    /// - SeeAlso: ``resolve(_:)`` for an optional, non-failing variant.
    func resolveRequired<Service>(_ serviceType: Service.Type) -> Service
    
    /// Resolves a required instance of a service by its interface type and casts it to a specific implementation,
    /// or triggers a runtime failure if the service is not registered or the cast fails.
    ///
    /// This method allows you to retrieve a service that was registered under an interface (such as a protocol)
    /// and obtain it as a concrete implementation type. Unlike ``resolve(_:as:)``, which returns `nil` when a
    /// service cannot be found or the cast fails, this variant enforces the contract that the service must exist
    /// and be castable, allowing clients to avoid optional handling and surface configuration issues early.
    ///
    /// - Parameters:
    ///   - interfaceType: The metatype of the interface under which the service was registered (e.g., `UserServiceInterface.self`).
    ///     Defaults to `Implementation.Interface.self` if not specified.
    ///   - implementationType: The concrete implementation type to cast the resolved service to (e.g., `UserService.self`).
    /// - Returns: An instance of the concrete implementation.
    /// - Precondition: A matching service must be registered and castable to the implementation type. Implementations
    ///   are expected to trap (e.g., via `preconditionFailure` or `fatalError`) if the service cannot be found or the cast fails.
    ///
    /// - Note: This method is provided as a convenience for scenarios where you need the concrete type rather than
    ///   the interface. In most cases, prefer resolving by interface alone using `resolveRequired(_:)` to maintain loose coupling.
    ///   This method is particularly useful in SwiftUI previews, where you may want to resolve a service
    ///   that has been registered with a mock implementation, allowing you to retrieve the mock directly
    ///   for additional configuration or verification.
    ///
    /// Example:
    /// ```swift
    /// // Resolve as a specific implementation (crashes if not registered)
    /// let concreteService = provider.resolveRequired(as: UserService.self)
    ///
    /// // Or explicitly specify the interface
    /// let explicitService = provider.resolveRequired(UserServiceInterface.self, as: UserService.self)
    /// ```
    ///
    /// - SeeAlso: ``resolve(_:as:)`` for an optional, non-failing variant.
    func resolveRequired<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type,
        as implementationType: Implementation.Type
    ) -> Implementation where Interface.Type == Implementation.Interface.Type
    
}

extension ServiceProvider {
    
    public func resolve<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type = Implementation.Interface.self,
        as implementationType: Implementation.Type
    ) -> Implementation? where Interface.Type == Implementation.Interface.Type {
        return resolve(interfaceType.self) as? Implementation
    }
    
    public func resolveRequired<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type = Implementation.Interface.self,
        as implementationType: Implementation.Type
    ) -> Implementation where Interface.Type == Implementation.Interface.Type {
        if let service = resolveRequired(interfaceType.self) as? Implementation {
            return service
        } else {
            fatalError("Try to resolve a required service by casting it to a concrete type, but it is not registered. Service: \(String(describing: implementationType))")
        }
    }
    
}
