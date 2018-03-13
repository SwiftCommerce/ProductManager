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
