final class Category: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    
    let name: String
    
    init(name: String) { self.name = name }
    
    func translations(with executor: DatabaseConnectable) -> Future<[CategoryTranslation]> {
        return self.assertID().flatMap(to: [CategoryTranslation].self, { (id) in
            return try self.translations.query(on: executor).all()
        })
    }
}

// MARK: - Public

struct CategoryResponseBody: Content {
    let id: Int?
    let name: String
    let subcategories: [CategoryResponseBody]
    let translations: [TranslationResponseBody]
}

extension Future where T == CategoryResponseBody {
    init(category: Category, executedWith executor: DatabaseConnectable) {
        self = Future.flatMap({
            let categories = try category.subCategories.query(on: executor).all().flatMap(to: [CategoryResponseBody].self) { (categories) in
                return categories.map({ Future(category: $0, executedWith: executor) }).flatten()
            }
            
            return Async.map(to: CategoryResponseBody.self, categories, category.translations(with: executor)) { (subCategories, translations) in
                return CategoryResponseBody(
                    id: category.id,
                    name: category.name,
                    subcategories: subCategories,
                    translations: translations.map({ TranslationResponseBody($0, price: nil) })
                )
            }
        })
    }
}
