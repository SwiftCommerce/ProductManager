final class Category: Content, MySQLModel, Migration {
    var id: Int?
    
    let name: String
    var parentId: Category.ID?
    
    init(name: String) { self.name = name }
    
    func assertId() -> Future<Category.ID> {
        let result = Promise<Category.ID>()
        
        if let id = self.id {
            result.complete(id)
        } else {
            fatalError("FIXME: Fail promise with `FluentError`")
//            result.fail(<#T##error: Error##Error#>)
        }
        
        return result.future
    }
    
    func translation(with executor: DatabaseConnectable) -> Future<CategoryTranslation> {
        return self.assertId().flatMap(to: CategoryTranslation?.self, { (id) in
            return CategoryTranslation.query(on: executor).filter(\.parentId == id).first()
        }).unwrap(or: Abort(.internalServerError, reason: "No category translation found for category \(self.id ?? -1)"))
    }
}
