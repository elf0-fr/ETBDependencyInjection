
public protocol Service: Injectable {
    
    associatedtype Interface
    
    static func initialization(provider: any ServiceProvider) -> Interface
    
}

extension Service {
    
    public static func initialization(provider: any ServiceProvider) -> Interface {
        Self.init(provider: provider) as! Interface
    }
    
}
