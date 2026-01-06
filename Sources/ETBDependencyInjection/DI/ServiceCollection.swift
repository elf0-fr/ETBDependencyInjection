
public protocol ServiceCollection {
    
    @discardableResult func register<Interface>(
        _ interfaceType: Interface.Type,
        factory: @escaping (any ServiceProvider) -> Interface
    ) -> ServiceCollection
    
    @discardableResult func register<Interface, Implementation: Service>(
        _ interfaceType: Interface.Type,
        as implementationType: Implementation.Type
    ) -> any ServiceCollection where Interface.Type == Implementation.Interface.Type

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
