import ETBDependencyInjection

// MARK: 1
@Service(MyServiceImpl.self)
class MyServiceImpl: Service {
    required init(provider: any ServiceProvider) {
        
    }
}


// MARK: 2
protocol MyService: Service {}

@Service(MyService.self)
class MyServiceImpl2: MyService {
    required init(provider: any ServiceProvider) {
        
    }
}


// MARK: 3
@Service(MyServiceImpl3.self)
class MyServiceImpl3: Service {
    required init(provider: any ServiceProvider) {
        
    }
    
    typealias Interface = MyServiceImpl3
}


// MARK: 4
@Service(MyServiceImpl4.self)
public class MyServiceImpl4: Service {
    public required init(provider: any ServiceProvider) {
        
    }
}
