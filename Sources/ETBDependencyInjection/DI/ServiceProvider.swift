
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
    
}
