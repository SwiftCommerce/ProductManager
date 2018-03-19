@_exported import FluentMySQL
@_exported import Vapor

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    // Register providers first
    try services.register(FluentMySQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a MySQL database
    var databases = DatabaseConfig()
    let databaseName = "product_manager"
    databases.add(database: MySQLDatabase(hostname: "localhost", user: "root", password: nil, database: databaseName), as: .mysql)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: Product.self, database: .mysql)
    migrations.add(model: Price.self, database: .mysql)
    migrations.add(model: Attribute.self, database: .mysql)
    migrations.add(model: ProductCategory.self, database: .mysql)
    migrations.add(model: ProductAttribute.self, database: .mysql)
    migrations.add(model: ProductTranslation.self, database: .mysql)
    migrations.add(model: CategoryTranslation.self, database: .mysql)
    migrations.add(model: ProductTranslationPivot.self, database: .mysql)
    migrations.add(model: CategoryTranslationPivot.self, database: .mysql)
    
    services.register(databases)
    services.register(migrations)
}
