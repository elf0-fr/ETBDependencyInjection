
@attached(extension, conformances: ETBDependencyInjection.Service)
@attached(member, names: named(Interface))
public macro Service<Service>(_ serviceType: Service) = #externalMacro(module: "ETBDependencyInjectionMacros", type: "ServiceMacro")

@attached(extension, conformances: ETBDependencyInjection.Injectable)
public macro Injectable() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectableMacro")

@attached(peer, names: prefixed(_injection_))
@attached(accessor, names: named(get), named(set))
public macro Injection() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectionMacro")
