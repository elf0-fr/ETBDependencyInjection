
/// A lightweight protocol that marks a type as capable of receiving dependencies from a `ServiceProvider`.
///
/// Conforming types declare a `provider` property and an initializer that accepts a `ServiceProvider`,
/// enabling a consistent pattern for dependency injection across your codebase.
///
/// Adoption
/// - Conform to `Injectable` when your type requires access to services (e.g., networking, storage,
///   logging) that are resolved at runtime.
/// - Prefer initializing instances with `init(provider:)` to ensure they are fully configured with a
///   valid provider at creation time.
/// - The `provider` property is optional to support scenarios where an instance may be created without
///   an active provider or receives one later (e.g., during testing or delayed composition).
///
/// Thread Safety
/// - `ServiceProvider` implementations may have specific threading guarantees. Ensure you respect those
///   guarantees when storing or using the `provider`.
///
/// Testing
/// - In tests, pass a mock or test double conforming to `ServiceProvider` via `init(provider:)`.
/// - You may also set `provider` to `nil` to validate behavior when dependencies are unavailable.
///
/// See Also
/// - `ServiceProvider`: The abstraction responsible for resolving and supplying dependencies.
public protocol Injectable {
    
    /// A reference to the `ServiceProvider` used to resolve and supply dependencies for this instance.
    /// 
    /// - Note: This property is optional to allow for scenarios where an instance may be created without
    ///   an active provider or where the provider can be injected later.
    /// - Important: When implementing `Injectable`, prefer using the `init(provider:)` initializer to
    ///   ensure the instance is properly configured with a provider at creation time.
    /// - SeeAlso: `ServiceProvider`, `init(provider:)`
    var provider: (any ServiceProvider)? { get }
    
    init(provider: any ServiceProvider)
    
}
