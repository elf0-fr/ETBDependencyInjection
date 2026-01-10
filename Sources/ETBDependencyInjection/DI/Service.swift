
/// A foundational protocol for defining application services that can be resolved via dependency injection.
///
/// Conforming types represent concrete services that provide functionality to the rest of the app.
/// `Service` integrates with your dependency injection system through `Injectable` and exposes a
/// public-facing `Interface` that callers use, allowing you to hide implementation details and
/// swap implementations (e.g., for testing).
///
/// Key concepts:
/// - Decoupling: Define an `Interface` that represents what the service does, not how it does it.
/// - Testability: Provide mock or fake implementations of the same `Interface`.
/// - Flexibility: The `Interface` can be a protocol, a lightweight facade type, or the service type itself.
///
/// Usage:
/// - Conform your concrete service to `Service`.
/// - Choose an `Interface` shape that fits your module boundary (protocol, facade struct, or `Self`).
/// - Implement `init(provider:)` from `Injectable` to receive dependencies.
/// - Consumers obtain an instance via `Self.initialization(provider:)`, which returns the `Interface`.
///
/// Example:
/// ```swift
/// protocol UserServiceInterface {
///     func fetchCurrentUser() async throws -> User
/// }
///
/// final class UserService: Service {
///     typealias Interface = UserServiceInterface
///
///     // Conform to the interface
///     func fetchCurrentUser() async throws -> User { /* ... */ }
///
///     // Satisfy Injectable protocol ...
/// }
///
/// // Elsewhere:
/// let api: UserServiceInterface = UserService.initialization(provider: container)
/// ```
///
/// Notes:
/// - If you set `Interface == Self`, ensure the concrete type is what you want to expose publicly.
/// - The default `initialization(provider:)` implementation constructs `Self` via `Injectable` and
///   force-casts to `Interface`. Ensure your `Interface` choice aligns with the concrete instance
///   to avoid runtime casting failures.
public protocol Service: Injectable {
    
    /// A type that represents the public-facing API or contract exposed by a `Service`.
    ///
    /// Conforming services define an `Interface` to decouple their internal implementation
    /// from the capabilities they expose to consumers. This enables:
    /// - Dependency inversion: Callers depend on abstractions rather than concrete types.
    /// - Easier testing: Mocks or fakes can implement the same interface.
    /// - Implementation hiding: Internal details remain private to the service.
    ///
    /// Typical patterns:
    /// - `Interface` is a protocol that the service instance conforms to.
    /// - `Interface` is a lightweight facade struct that forwards to the underlying service.
    /// - `Interface` can be the concrete service type itself when abstraction is not needed.
    ///
    /// The `initialization(provider:)` factory returns this `Interface`, allowing callers
    /// to interact with the service without knowing its concrete implementation.
    ///
    /// Example:
    /// ```swift
    /// protocol UserServiceInterface {
    ///     func fetchCurrentUser() async throws -> User
    /// }
    ///
    /// class UserService: Service {
    ///     typealias Interface = UserServiceInterface
    ///     // ...
    /// }
    /// ```
    ///
    /// Choose an `Interface` shape that best fits your module boundaries and testing strategy.
    associatedtype Interface
    
    static func initialization(provider: any ServiceProvider) -> Interface
    
}

extension Service {
    
    public static func initialization(provider: any ServiceProvider) -> Interface {
        Self.init(provider: provider) as! Interface
    }
    
}
