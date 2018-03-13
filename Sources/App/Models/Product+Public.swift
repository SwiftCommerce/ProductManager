struct ProductResponseBody: Content {
    let id: Int?
    let sku: String
    let attributes: [Attribute]
    let price: Price
    let translations: [ProductTranslation]
    let categories: [Category]
}

extension Future where T == ProductResponseBody {
    init(product: Product, executedWith executor: DatabaseConnectable) {
        let attributes = product.attributes(with: executor)
        let price = product.price(with: executor)
        let translations = product.translations(with: executor)
        let categories = product.categories(with: executor)
        
        self = App.map(to: ProductResponseBody.self, attributes, price, translations, categories, into: { (attributes, price, translations, categories) in
            return ProductResponseBody(id: product.id, sku: product.sku, attributes: attributes, price: price, translations: translations, categories: categories)
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

func map<T, A, B, C, D>(to type: T.Type, _ a: Future<A>, _ b: Future<B>, _ c: Future<C>, _ d: Future<D>, into completion: @escaping (A, B, C, D)throws -> T) -> Future<T> {
    return Async.flatMap(to: T.self, a, b, c) { (ar, br, cr) -> (Future<T>) in
        d.map(to: T.self, { (dr) -> T in
            return try completion(ar, br, cr, dr)
        })
    }
}
