
public protocol Injectable {
    
    var provider: (any ServiceProvider)? { get }
    
    init(provider: any ServiceProvider)
    
}
