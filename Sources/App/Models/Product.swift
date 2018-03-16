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
            return try self.translations.query(on: executor).all()
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
        guard let id = self.id else { return Future(()) }
        
        let categories = self.categories(with: executor).map(to: [Int].self) { categories in
            return categories.compactMap({ $0.id })
        }.flatMap(to: [Int].self) { (ids) in
            return ProductCategory.query(on: executor).filter(\.productId == id).filter(\.categoryId, in: ids).delete().transform(to: ids)
        }.flatMap(to: Void.self) { (ids) in
            return Category.query(on: executor).filter(\.id, in: ids).delete()
        }
        let attributes = Attribute.query(on: executor).filter(\.productId == id).delete()
        let translation = self.translations.deleteConnections(on: executor)
        let product = self.delete(with: executor)
        
        return [categories, attributes, translation, product].flatten()
    }
}

// MARK: - Public

struct ProductResponseBody: Content {
    let id: Int?
    let sku: String
    let attributes: [Attribute]
    let translations: [TranslationResponseBody]
    let categories: [CategoryResponseBody]
}

extension Future where T == ProductResponseBody {
    init(product: Product, executedWith executor: DatabaseConnectable) {
        let attributes = product.attributes(with: executor)
        
        let translations = product.translations(with: executor).flatMap(to: [TranslationResponseBody].self) { $0.map({ translation in
            return translation.response(on: executor)
        }).flatten() }
        
        let categories = product.categories(with: executor).flatMap(to: [CategoryResponseBody].self) {
            $0.map({ Future<CategoryResponseBody>(category: $0, executedWith: executor) }).flatten()
        }
        
        self = Async.map(to: ProductResponseBody.self, attributes, translations, categories, { (attributes, translations, categories) in
            return ProductResponseBody(id: product.id, sku: product.sku, attributes: attributes, translations: translations, categories: categories)
        })
    }
}
