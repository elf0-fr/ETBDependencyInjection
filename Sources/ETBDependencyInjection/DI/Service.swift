
public protocol Service {
    
    associatedtype Interface
    
    init(provider: any ServiceProvider)
    
    static func initialization(provider: any ServiceProvider) -> Interface
    
}

extension Service {
    
    public static func initialization(provider: any ServiceProvider) -> Interface {
        Self.init(provider: provider) as! Interface
    }
    
}
