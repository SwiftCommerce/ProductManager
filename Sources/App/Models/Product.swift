final class Product: Content, MySQLModel, Migration {
    var id: Int?
    let sku: String
    
    init(sku: String) { self.sku = sku }
    
    func attributes(with executor: DatabaseConnectable) -> Future<[Attribute]> {
        let result = Promise<[Attribute]>()
        
        if let id = self.id {
            _ = Attribute.query(on: executor).filter(\.productId == id).all().do { (attributes) in
                result.complete(attributes)
            }
        } else {
            fatalError("FIXME: Fail prmise with `FluentError`")
//            result.fail(<#T##error: Error##Error#>)
        }
        
        return result.future
    }
}
