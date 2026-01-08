import ETBDependencyInjection
import SwiftUI
import Observation

// MARK: 1
@Service(MyServiceImpl.self)
class MyServiceImpl: Service {
    
    var provider: (any ServiceProvider)?
    
    required init(provider: any ServiceProvider) {
        
    }
    
}


// MARK: 2
protocol MyService: Service {}

@Service(MyService.self)
class MyServiceImpl2: MyService {
    
    var provider: (any ServiceProvider)?
    
    required init(provider: any ServiceProvider) {
        
    }
    
}


// MARK: 3
@Service(MyServiceImpl3.self)
class MyServiceImpl3: Service {
    
    var provider: (any ServiceProvider)?
    
    required init(provider: any ServiceProvider) {
        
    }
    
    typealias Interface = MyServiceImpl3
}


// MARK: 4
@Service(MyServiceImpl4.self)
public class MyServiceImpl4: Service {
    
    public var provider: (any ServiceProvider)?
    
    public required init(provider: any ServiceProvider) {
        
    }
    
}


// MARK: 5
@Service(MyServiceImpl5.self)
public class MyServiceImpl5 {
    
    public var provider: (any ServiceProvider)?

    public required init(provider: any ServiceProvider) {
        
    }
}


// MARK: 6
@Observable
@Injectable
class ViewModel {
    
    @Injection @ObservationIgnored var service: any MyService
    @Injection @ObservationIgnored var service2: any Service

    var provider: (any ServiceProvider)?
    
    public required init(provider: any ServiceProvider) {
        self.provider = provider
    }
    
}
