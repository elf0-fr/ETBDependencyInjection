
/// A dependency injection container abstraction that coordinates service registration and resolution.
///
/// Use a `Container` to:
/// - Register services and their lifetimes (singleton, scoped, transient) via `services`.
/// - Finalize configuration by calling `build()` once registrations are complete.
/// - Resolve services through the lazily created `provider` after a successful build.
///
/// Lifecycle:
/// 1. Access and mutate `services` to register all required types and factories.
/// 2. Call `build()` to finalize registrations and prepare the internal `ServiceProvider`.
/// 3. Access `provider` to resolve dependencies at runtime.
///
/// Concurrency and access guarantees are implementation-defined. Many implementations:
/// - Restrict or prohibit access to `services` after `build()` completes.
/// - Require `build()` to be called before `provider` is accessed.
/// - May throw if these rules are violated.
///
/// Typical usage:
/// - Configure during application startup, then resolve dependencies for the app’s lifetime.
/// - Call `build()` exactly once; repeated builds may lead to undefined behavior.
///
/// Error handling:
/// - Accessing `services` after build may throw, depending on the implementation.
/// - Accessing `provider` before build may throw.
/// - Implementations should document specific error types and conditions.
///
/// See also:
/// - `ServiceCollection` for registering services and lifetimes.
/// - `ServiceProvider` for resolving service instances.
public protocol Container {
    
    /// A collection used to register services and their lifetimes for this container.
    ///
    /// Use this collection to add service registrations (e.g., singleton, scoped, transient)
    /// before building the container. Registrations defined here are later consumed by
    /// `provider` to resolve concrete instances and perform dependency injection.
    ///
    /// - Important: Modify `services` prior to calling `build()`. Implementations may
    ///   restrict access after a successful build and can throw if accessed post-build.
    /// - Throws: An error if the collection is unavailable or cannot be accessed in the
    ///   current state (for example, after `build()` has finalized registrations).
    /// - Returns: An implementation of `ServiceCollection` that supports registering
    ///   service types and their corresponding factories or instances.
    var services: any ServiceCollection { get throws }
    
    /// A lazily initialized service resolver for the container.
    /// 
    /// Access this property to resolve concrete service instances that were
    /// registered in `services`. The provider is typically created and configured
    /// during `build()`, and is responsible for honoring service lifetimes
    /// (e.g., singleton, scoped, transient) and performing dependency injection.
    /// 
    /// - Important: You must call `build()` before accessing `provider`.
    ///   Accessing this property prior to a successful build may throw.
    /// 
    /// - Throws: An error if the provider is unavailable or not yet built.
    /// 
    /// - Returns: An implementation of `ServiceProvider` capable of resolving services
    ///   previously registered via `services`.
    var provider: any ServiceProvider { get throws }
    
    /// Builds and configures the container's service infrastructure.
    /// 
    /// Call this method to perform any setup required before resolving services,
    /// such as registering implementations, configuring lifetimes, and preparing
    /// the underlying `ServiceProvider`.
    ///
    /// - Important: This should be invoked once during application startup,
    ///   after registering services in `services` and before accessing  `provider`. Calling it multiple times
    ///   may lead to undefined behavior depending on the concrete implementation.
    ///
    /// - Note: Implementations may throw during access to `services` if `build()` has been called.
    ///
    ///    Implementations may throw during access to `provider` if `build()` has not been called.
    ///
    func build()
    
}
