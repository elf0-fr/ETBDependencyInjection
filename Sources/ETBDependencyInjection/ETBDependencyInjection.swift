
@attached(extension, conformances: ETBDependencyInjection.Service)
@attached(member, names: named(Interface))
public macro Service<Service>(_ serviceType: Service) = #externalMacro(module: "ETBDependencyInjectionMacros", type: "ServiceMacro")
