import ETBDependencyInjection
import SwiftUI
import Observation

// MARK: Service
protocol MyService: Service {}

@Service(MyService.self)
class MyServiceImpl: MyService {
    
    @Injection var service: any MyService
    
    required init(provider: any ServiceProvider) {
        self.provider = provider
    }
    
}


// MARK: Injectable
@Observable
@Injectable
class ViewModel {
    
    @Injection @ObservationIgnored var service: any MyService
    @Injection @ObservationIgnored var service2: any Service

    var provider: (any ServiceProvider)?
    
    init(provider: any ServiceProvider) {
        self.provider = provider
    }
    
}

