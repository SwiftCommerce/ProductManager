final class Category: Content, MySQLModel, Migration, Parameter {
    var id: Int?
    
    let name: String
    var parentId: Category.ID?
    
    init(name: String) { self.name = name }
    
    func translations(with executor: DatabaseConnectable) -> Future<[CategoryTranslation]> {
        return self.assertID().flatMap(to: [CategoryTranslation].self, { (id) in
            return try self.translations.query(on: executor).all()
        })
    }
    
    func subCategories(with executor: DatabaseConnectable) -> Future<[Category]> {
        return self.assertID().flatMap(to: [Category].self, { (id) in
            return Category.query(on: executor).filter(\.parentId == id).all()
        })
    }
    
    func add(child category: Category)throws {
        guard let id = self.id else {
            fatalError("FIXME: Throw a `FluentError`")
        }
        category.parentId = id
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
        let categories = category.subCategories(with: executor).flatMap(to: [CategoryResponseBody].self) { (categories) in
            return categories.map({ Future(category: $0, executedWith: executor) }).flatten()
        }
        
        self = Async.map(to: CategoryResponseBody.self, categories, category.translations(with: executor)) { (subCategories, translations) in
            return CategoryResponseBody(
                id: category.id,
                name: category.name,
                subcategories: subCategories,
                translations: translations.map({ TranslationResponseBody($0, price: nil) })
            )
        }
    }
}
