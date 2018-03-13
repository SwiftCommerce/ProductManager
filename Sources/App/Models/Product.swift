final class Product: Content, MySQLModel, Migration, Parameter {
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
    
    func delete(with executor: DatabaseConnectable) -> Future<Void> {
        guard self.id != nil else { return Future(()) }
        
        let categories = self.categories(with: executor).flatMap(to: Void.self) { $0.map({ $0.delete(on: executor) }).flatten().transform(to: ()) }
        let attributes = self.attributes(with: executor).flatMap(to: Void.self) { $0.map({ $0.delete(on: executor) }).flatten().transform(to: ()) }
        let translation = self.translation(with: executor).delete(on: executor).transform(to: ())
        let product = self.delete(on: executor).delete(on: executor).transform(to: ())
        let price = self.price(with: executor).delete(on: executor).transform(to: ())
        
        return [categories, attributes, translation, product, price].flatten()
    }
}
