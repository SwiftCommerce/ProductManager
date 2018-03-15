final class TranslationController<Parent: Model & Parameter, Trans: Translation>: RouteCollection {
    let root: String
    
    init(root: String) {
        self.root = root
    }
    
    func boot(router: Router) throws {}
}
