
@attached(extension, conformances: ETBDependencyInjection.Service)
@attached(member, names: named(Interface))
public macro Service<Service>(_ serviceType: Service) = #externalMacro(module: "ETBDependencyInjectionMacros", type: "ServiceMacro")

@attached(extension, conformances: ETBDependencyInjection.Injectable)
//@attached(memberAttribute)
public macro Injectable() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectableMacro")

@attached(peer, names: suffixed(_Injection))
@attached(accessor)
public macro Injection() = #externalMacro(module: "ETBDependencyInjectionMacros", type: "InjectionMacro")
