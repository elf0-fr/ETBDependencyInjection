
/// A lightweight registration container for configuring dependency resolution.
///
/// ServiceCollection is used during application composition to register how interfaces
/// (usually protocols) should be fulfilled. You add registrations—either by providing a
/// factory closure or by referencing a concrete `Service` implementation—and then call
/// ``build()`` to produce a ``ServiceProvider``. The resulting provider resolves the
/// registered interfaces to concrete instances at runtime.
///
/// Typical usage:
/// - Create or obtain a `ServiceCollection`.
/// - Register interfaces with their factories or `Service` implementations.
/// - Call ``build()`` to obtain a `ServiceProvider`.
/// - Use the provider to resolve dependencies throughout your app.
///
/// Registration methods:
/// - ``register(_:factory:)``: Supply a custom factory closure that can use the
///   provider to resolve transitive dependencies.
/// - ``register(_:as:)``: Register a concrete type conforming to ``Service`` that
///   exposes a static `initialization(provider:)` factory.
///
/// Notes:
/// - The lifecycle (e.g., transient vs. singleton), threading guarantees, and duplicate
///   registration behavior are determined by the concrete ``ServiceProvider`` built from
///   the collection.
/// - The collection is a configuration-time construct; once you call ``build()``,
///   subsequent changes to the collection do not affect previously built providers.
///
/// See also:
/// - ``ServiceProvider`` for resolving services.
/// - ``Service`` for implementation types that can be registered via ``register(_:as:)``.
public protocol ServiceCollection {
    
    /// Registers a factory closure that produces instances for the specified interface type in this collection.
    ///
    /// Use this method to supply a custom factory for resolving a dependency. The factory receives the
    /// `ServiceProvider` built from this collection, allowing it to resolve further dependencies as needed
    /// when constructing the instance.
    ///
    /// - Parameters:
    ///   - interfaceType: The protocol or concrete type that will be used as the lookup key when resolving
    ///     the service. Typically this is a protocol that your implementation conforms to.
    ///   - factory: A closure that takes the `ServiceProvider` and returns an instance of the requested
    ///     interface type. The closure can use the provider to resolve any transitive dependencies.
    /// - Returns: The current `ServiceCollection` to allow chaining additional registrations.
    /// - Important: The factory is expected to be side‑effect free other than creating/returning the service
    ///   instance. Lifecycle (e.g., transient/singleton) and invocation timing are determined by the
    ///   `ServiceProvider` implementation built from this collection.
    /// - Note: If multiple registrations are made for the same `interfaceType`, the behavior on resolution
    ///   depends on the underlying `ServiceProvider` implementation (e.g., last write wins or error).
    /// - SeeAlso: ``build()`` to create a `ServiceProvider` capable of resolving the registered services.
    @discardableResult func register<Interface>(
        _ interfaceType: Interface.Type,
        factory: @escaping (any ServiceProvider) -> Interface
    ) -> ServiceCollection
    
    /// Registers a concrete `Service` implementation for an interface in this collection.
    ///
    /// Use this overload when your implementation type conforms to `Service` and provides a static
    /// `initialization(provider:)` factory. The registration associates the provided `interfaceType`
    /// (typically a protocol) with the `implementationType`, so that a `ServiceProvider` built from
    /// this collection can resolve the interface to instances produced by the implementation’s
    /// initialization routine.
    ///
    /// - Generic Parameters:
    ///   - Interface: The protocol or concrete type that consumers will request from the provider.
    ///   - Implementation: A concrete type conforming to `Service` whose `Interface` associated type
    ///     matches `Interface`.
    /// - Parameters:
    ///   - interfaceType: The interface that will be used as the lookup key when resolving the service.
    ///     Defaults to `Implementation.Interface.self`, allowing omission when they match.
    ///   - implementationType: The concrete `Service` type that will be constructed to fulfill the
    ///     interface.
    /// - Returns: The current `ServiceCollection` to allow chaining additional registrations.
    /// - Important: This method registers the implementation by referencing its `Service.initialization(provider:)`
    ///   factory. Instance lifetime (e.g., transient vs. singleton) and when the factory is invoked are
    ///   determined by the `ServiceProvider` built from this collection.
    /// - Note: If the same `interfaceType` is registered multiple times, the behavior on resolution
    ///   depends on the `ServiceProvider` implementation (e.g., last-write-wins or error).
    /// - SeeAlso: ``Service``, ``ServiceProvider``, ``build()``.
    @discardableResult func register<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type,
        as implementationType: Implementation.Type
    ) -> any ServiceCollection where Interface.Type == Implementation.Interface.Type

    /// Builds and returns a `ServiceProvider` capable of resolving services registered in this collection.
    ///
    /// Call this method after you have finished registering all of your services using the `register` APIs.
    /// The returned provider captures the registration state at the time of the call and is then used to
    /// resolve dependencies throughout your application.
    ///
    /// - Returns: A `ServiceProvider` that can resolve instances for all services registered in this collection.
    /// - Important: The exact lifecycle semantics (e.g., transient vs. singleton), threading guarantees,
    ///   and conflict resolution (such as handling duplicate registrations) are determined by the concrete
    ///   `ServiceProvider` implementation produced by this collection.
    /// - Note: Subsequent modifications to the `ServiceCollection` after calling `build()` do not affect
    ///   previously built providers. Build a new provider if you need to reflect additional registrations.
    /// - SeeAlso: ``register(_:factory:)``, ``register(_:as:)``, ``ServiceProvider``.
    func build() -> ServiceProvider
    
}

extension ServiceCollection {
    
    public func register<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type = Implementation.Interface.self,
        as implementationType: Implementation.Type
    ) -> any ServiceCollection where Interface.Type == Implementation.Interface.Type {
        return register(interfaceType) { Implementation.initialization(provider: $0) }
    }
    
}
