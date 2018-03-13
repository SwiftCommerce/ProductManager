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
