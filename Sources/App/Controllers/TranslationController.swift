final class TranslationController<Parent: MySQLModel & Parameter, Trans: Translation>: RouteCollection where Parent.ResolvedParameter == Future<Parent> {
    typealias BasicResponse = Future<TranslationResponseBody>
    
    let root: String
    
    init(root: String) {
        self.root = root
    }
    
    func boot(router: Router) throws {
        let group = router.grouped(.constants([.string(root)]), Parent.parameter, "translations")
        
        group.get(use: index)
    }
    
    func index(_ request: Request)throws -> Future<[TranslationResponseBody]> {
        return try request.parameter(Parent.self).flatMap(to: [Trans].self) { parent in
            return Trans.query(on: request).filter(\.parentId == parent.id!).all()
        }.flatMap(to: [TranslationResponseBody].self, { (translations) in
            return translations.map({ $0.response(on: request) }).flatten()
        })
    }
}
