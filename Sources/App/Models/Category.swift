final class Category: Content, MySQLModel, Migration {
    var id: Int?
    
    let name: String
    var parentId: Category.ID?
    
    init(name: String) { self.name = name }
    
    func assertId() -> Future<Category.ID> {
        let result = Promise<Category.ID>()
        
        if let id = self.id {
            result.complete(id)
        } else {
            fatalError("FIXME: Fail promise with `FluentError`")
//            result.fail(<#T##error: Error##Error#>)
        }
        
        return result.future
    }
    
    func translations(with executor: DatabaseConnectable) -> Future<[CategoryTranslation]> {
        return self.assertId().flatMap(to: [CategoryTranslation].self, { (id) in
            return CategoryTranslation.query(on: executor).filter(\.parentId == id).all()
        })
    }
    
    func subCategories(with executor: DatabaseConnectable) -> Future<[Category]> {
        return self.assertId().flatMap(to: [Category].self, { (id) in
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
    let subcategories: [Category]
}

extension Future where T == CategoryResponseBody {
    init(category: Category, executedWith executor: DatabaseConnectable) {
        self = category.subCategories(with: executor).map(to: CategoryResponseBody.self, { (categories) in
            return CategoryResponseBody(id: category.id, name: category.name, subcategories: categories)
        })
    }
}

extension Future {
    func category(_ category: Category, with executor: DatabaseConnectable) -> Future<CategoryResponseBody> {
        return self.flatMap(to: CategoryResponseBody.self, { _ in
            return Future<CategoryResponseBody>(category: category, executedWith: executor)
        })
    }
}
