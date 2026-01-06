
public protocol Container {
    
    var services: any ServiceCollection { get throws }
    var provider: any ServiceProvider { get throws }
    
    func build()
    
}
