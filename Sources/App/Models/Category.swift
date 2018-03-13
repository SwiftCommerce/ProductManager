final class Category: Content, MySQLModel, Migration {
    var id: Int?
    let name: String
    
    init(name: String) { self.name = name }
    
    func translation(with executor: DatabaseConnectable) -> Future<CategoryTranslation> {
        let result = Promise<CategoryTranslation>()
        
        if let id = self.id {
            _ = CategoryTranslation.query(on: executor).filter(\.parentId == id).first().unwrap(or:
                    Abort(.internalServerError, reason: "No category translation found for category \(self.id ?? -1)")
                ).do({ (translation) in
                    result.complete(translation)
                })
        } else {
            fatalError("FIXME: Fail the future with a `FluentError`")
//            result.fail(<#T##error: Error##Error#>)
        }
        
        return result.future
    }
}
