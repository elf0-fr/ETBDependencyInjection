
/// Declares a service type for dependency injection and generates a nested `Interface` type
/// along with protocol conformances required by the ETBDependencyInjection system.
///
/// Use this macro on a concrete type that represents a service in your application. The macro:
/// - Synthesizes conformance to `ETBDependencyInjection.Service`.
/// - Generates a nested `Interface` type that represents the service’s public interface
///   to be used by dependents (e.g., for injection and mocking).
///
/// Parameters:
/// - serviceType: A marker parameter used to drive the macro expansion. Pass the type you are
///   annotating (e.g., `Self`) to clearly indicate the service being declared. The value itself
///   is not used at runtime.
///
/// Expansion:
/// - Attaches an extension that conforms the annotated type to `ETBDependencyInjection.Service`.
/// - Adds a member named `Interface`, typically a protocol or type alias, representing the service’s
///   interface exposed to consumers.
///
/// Usage:
/// ```swift
/// @Service(Self)
/// final class AnalyticsService {
///     func track(event: String) { /* ... */ }
/// }
///
/// // The macro generates:
/// // - extension AnalyticsService: ETBDependencyInjection.Service { /* ... */ }
/// // - nested `Interface` to be used for injection and mocking.
/// ```
///
/// Notes:
/// - The shape of the generated `Interface` may depend on the macro’s configuration and your type’s
///   public API. Refer to ETBDependencyInjectionMacros.ServiceMacro for exact generation details.
/// - Combine with `@Injectable` on consuming types and `@Injection` on properties to wire dependencies.
///
/// See also:
/// - `@Injectable` for types that receive dependencies.
/// - `@Injection` for property wrappers that bind to a service interface.
@attached(extension, conformances: ETBDependencyInjection.Service)
@attached(member, names: named(Interface), named(provider))
public macro Service<Service>(_ serviceType: Service) = #externalMacro(module: "ETBDependencyInjectionMacros", type: "ServiceMacro")

/// Marks a concrete type as able to receive dependencies via the ETBDependencyInjection system,
/// synthesizing conformance to `ETBDependencyInjection.Injectable`.
///
/// Apply this macro to classes or structs that consume services injected by the dependency
/// injection framework. The macro:
/// - Adds conformance to `ETBDependencyInjection.Injectable`.
/// - Enables use of `@Injection` property wrappers within the annotated type to bind service
///   interfaces to their implementations via the provider property.
/// - Participates in code generation performed by `ETBDependencyInjectionMacros.InjectableMacro`
///   to wire up dependency resolution at runtime or during testing.
///
/// Typical usage:
/// ```swift
/// @Injectable
/// final class HomeViewModel {
///     @Injection var analytics: AnalyticsService.Interface
///     @Injection var network: NetworkService.Interface
///
///     // ...
/// }
/// ```
///
/// Notes:
/// - Use in combination with `@Service(Self)` on service providers and `@Injection` on dependent
///   properties to complete the dependency graph.
/// - The macro itself does not introduce stored properties; it only synthesizes protocol
///   conformance and supporting glue as defined by `InjectableMacro`.
/// - Refer to `ETBDependencyInjection.Injectable` and `ETBDependencyInjectionMacros.InjectableMacro`
///   for exact behavior and requirements.
///
/// See also:
/// - `@Service` to declare a service and generate its `Interface`.
/// - `@Injection` to inject a service interface into an `@Injectable` type.
@attached(extension, conformances: ETBDependencyInjection.Injectable)
public macro Injectable() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectableMacro")

/// Property wrapper macro that injects a service interface into an `Injectable` type,
/// wiring it to the ETBDependencyInjection resolution system.
///
/// Apply `@Injection` to a stored property. The macro:
/// - Generates a peer backing storage (prefixed with `_injection_`) to manage resolution state.
/// - Synthesizes get/set accessors that resolve the dependency from the active container,
///   environment, or test harness as defined by `ETBDependencyInjectionMacros.InjectionMacro`.
/// - Enables seamless swapping of implementations (e.g., production vs. mock) without changing
///   consumer code.
///
/// Usage:
/// ```swift
/// @Injectable
/// final class HomeViewModel {
///     @Injection var analytics: AnalyticsService
///     @Injection var network: NetworkService
///
///     func didOpen() {
///         analytics.track(event: "home_opened")
///     }
/// }
/// ```
///
/// Notes:
/// - Resolution behavior (lifecycle, caching, overrides) is defined by the macro implementation
///   in `ETBDependencyInjectionMacros.InjectionMacro`.
/// - During testing, you can register or override service implementations to supply mocks/fakes,
///   and injected properties will reflect those registrations.
/// - The macro does not itself define thread-safety guarantees; ensure your service implementations
///   are safe for your concurrency model.
///
/// See also:
/// - `@Service` for declaring a service and generating its `Interface`.
/// - `@Injectable` for enabling injection on consumer types.
/// - `ETBDependencyInjection.Service` and `ETBDependencyInjection.Injectable` for protocol details.
@attached(peer, names: prefixed(_injection_))
@attached(accessor, names: named(get), named(set))
public macro Injection() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectionMacro")
