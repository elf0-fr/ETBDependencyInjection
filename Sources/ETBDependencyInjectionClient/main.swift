import ETBDependencyInjection


@Service(MyServiceImpl.self)
class MyServiceImpl: Service {
    required init(provider: any ServiceProvider) {
        
    }
}

extension MyServiceImpl {
    typealias Interface = MyServiceImpl
}


protocol MyService: Service {}

@Service(MyService.self)
class MyServiceImpl2: MyService {
    required init(provider: any ServiceProvider) {
        
    }
}

extension MyServiceImpl2 {
    typealias Interface = MyService
}
