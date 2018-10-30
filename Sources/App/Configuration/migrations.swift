import Fluent

func migrations(config: inout MigrationConfig)throws {
    config.add(model: Category.self, database: .mysql)
    config.add(model: Product.self, database: .mysql)
    config.add(model: Price.self, database: .mysql)
    config.add(model: Attribute.self, database: .mysql)
    config.add(model: ProductPrice.self, database: .mysql)
    config.add(model: CategoryPivot.self, database: .mysql)
    config.add(model: ProductCategory.self, database: .mysql)
    config.add(model: ProductAttribute.self, database: .mysql)
    config.add(model: ProductTranslation.self, database: .mysql)
    config.add(model: CategoryTranslation.self, database: .mysql)
}
