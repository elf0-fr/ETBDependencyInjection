
/// A lightweight protocol that marks a type as capable of receiving dependencies from a `ServiceProvider`.
///
/// Conforming types declare a `provider` property. They are free to initialize that property as they want.
///
/// Adoption
/// - Conform to `Injectable` when your type requires access to services (e.g., networking, storage,
///   logging) that are resolved at runtime.
/// - The `provider` property is optional to support scenarios where an instance may be created without
///   an active provider or receives one later (e.g., during testing or delayed composition).
///
/// Thread Safety
/// - `ServiceProvider` implementations may have specific threading guarantees. Ensure you respect those
///   guarantees when storing or using the `provider`.
///
/// Testing
/// - In tests, pass a mock or test double directly or via the provider.
/// - You may also set `provider` to `nil` to validate behavior when dependencies are unavailable.
///
/// See Also
/// - `ServiceProvider`: The abstraction responsible for resolving and supplying dependencies.
public protocol Injectable {
    
    /// A reference to the `ServiceProvider` used to resolve and supply dependencies for this instance.
    /// 
    /// - Note: This property is optional to allow for scenarios where an instance may be created without
    ///   an active provider or where the provider can be injected later.
    /// - SeeAlso: `ServiceProvider`
    var provider: (any ServiceProvider)? { get }
    
}
