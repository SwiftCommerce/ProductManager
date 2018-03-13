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
    
    func price(with executor: DatabaseConnectable) -> Future<Price> {
        return self.assertId().flatMap(to: Price?.self, { (id) in
            return Price.query(on: executor).filter(\.productId == id).first()
        }).unwrap(or: Abort(.internalServerError, reason: "No price found for product \(self.id ?? -1)"))
    }
    
    func translation(with executor: DatabaseConnectable) -> Future<ProductTranslation> {
        return self.assertId().flatMap(to: ProductTranslation?.self, { (id) in
            return ProductTranslation.query(on: executor).filter(\.parentId == id).first()
        }).unwrap(or: Abort(.internalServerError, reason: "No product translation found for product \(self.id ?? -1)"))
    }
    
    func categories(with executor: DatabaseConnectable) -> Future<[Category]> {
        let result = Promise<[Category]>()
        
        do {
            return try self.categories.query(on: executor).all()
        } catch { result.fail(error) }
        
        return result.future
    }
}
