final class Product: Content, MySQLModel, Migration {
    var id: Int?
    let sku: String
    
    init(sku: String) { self.sku = sku }
    
    func assertId() -> Future<Product.ID> {
        let result = Promise<Product.ID>()
        
        if let id = self.id {
            result.complete(id)
        } else {
            fatalError("FIXME: Fail promise with `FluentError`")
//            result.fail(<#T##error: Error##Error#>)
        }
        
        return result.future
    }
    
    func attributes(with executor: DatabaseConnectable) -> Future<[Attribute]> {
        return self.assertId().flatMap(to: [Attribute].self, { (id) in
            return Attribute.query(on: executor).filter(\.productId == id).all()
        })
    }
}
