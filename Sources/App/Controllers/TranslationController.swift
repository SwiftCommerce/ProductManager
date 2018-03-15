final class TranslationController<Parent: Model & Parameter, Trans: Translation>: RouteCollection {
    typealias BasicResponse = Future<TranslationResponseBody>
    
    let root: String
    
    init(root: String) {
        self.root = root
    }
    
    func boot(router: Router) throws {
        let group = router.grouped(.constants([.string(root)]), Parent.parameter, "translations")
    }
}
