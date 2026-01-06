
public protocol ServiceProvider {
    
    func resolve<Service>(_ serviceType: Service.Type) -> Service?
    func resolveRequired<Service>(_ serviceType: Service.Type) -> Service
    
}
