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
    // Register the `FluentMySQLProvider`.
    // This creates the connection to the database and runs the model migrations.
    try services.register(FluentMySQLProvider())

    // Create a router,
    // register all the app's routes to it,
    // and register the router with the app.
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware with the app's services.
    // These middleware will automaticly be added to all routes.
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware(configuration: .default)) // Adds Cross-Origin-Request headers to all responses
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a MySQL database.
    var databases = DatabaseConfig()
    
    if !env.isRelease {
        databases.enableLogging(on: .mysql)
    }
    
    // Configure the MySQL Database.
    // If we are in Vapor Cloud, we use the available env vars,
    // otherwise we use the values for local development
    let config = MySQLDatabaseConfig.init(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database:  Environment.get("DATABASE_DB") ?? "product_manager"
    )
    databases.add(database: MySQLDatabase(config: config), as: .mysql)

    // Configure migrations.
    // Add all models to the migration config so the `FluentProvider` will create tables for them in the database.
    var migrations = MigrationConfig()
    migrations.add(model: Category.self, database: .mysql)
    migrations.add(model: Product.self, database: .mysql)
    migrations.add(model: Price.self, database: .mysql)
    migrations.add(model: Attribute.self, database: .mysql)
    migrations.add(model: CategoryPivot.self, database: .mysql)
    migrations.add(model: ProductCategory.self, database: .mysql)
    migrations.add(model: ProductTranslation.self, database: .mysql)
    migrations.add(model: CategoryTranslation.self, database: .mysql)
    
    // Register Database and Migration configurations with the application services.
    services.register(databases)
    services.register(migrations)
}
