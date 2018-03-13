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
    
    func translations(with executor: DatabaseConnectable) -> Future<[ProductTranslation]> {
        return self.assertId().flatMap(to: [ProductTranslation].self, { (id) in
            return ProductTranslation.query(on: executor).filter(\.parentId == id).all()
        })
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
        let translation = self.translations(with: executor).flatMap(to: Void.self) { $0.map({ $0.delete(on: executor) }).flatten().transform(to: ()) }
        let product = self.delete(on: executor).delete(on: executor).transform(to: ())
        
        return [categories, attributes, translation, product].flatten()
    }
}

// MARK: - Public

struct ProductResponseBody: Content {
    let id: Int?
    let sku: String
    let attributes: [Attribute]
    let translations: [ProductTranslation]
    let categories: [Category]
}

extension Future where T == ProductResponseBody {
    init(product: Product, executedWith executor: DatabaseConnectable) {
        let attributes = product.attributes(with: executor)
        let translations = product.translations(with: executor)
        let categories = product.categories(with: executor)
        
        self = Async.map(to: ProductResponseBody.self, attributes, translations, categories, { (attributes, translations, categories) in
            return ProductResponseBody(id: product.id, sku: product.sku, attributes: attributes, translations: translations, categories: categories)
        })
    }
}

extension Future {
    func product(_ product: Product, with executor: DatabaseConnectable) -> Future<ProductResponseBody> {
        return self.flatMap(to: ProductResponseBody.self, { _ in
            return Future<ProductResponseBody>(product: product, executedWith: executor)
        })
    }
}
