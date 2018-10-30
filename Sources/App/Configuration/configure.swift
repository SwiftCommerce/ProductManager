@_exported import FluentMySQL
@_exported import Vapor
import JWTMiddleware

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
    
    // Registers a `JWTService` for verifying
    // incoming access tokens.
    let jwtProvider = JWTProvider { n, d in
        guard let d = d else { throw Abort(.internalServerError, reason: "Could not find environment variable 'JWT_SECRET'", identifier: "missingEnvVar") }
        
        let headers = JWTHeader(alg: "RS256", crit: ["exp", "aud"], kid: "")
        return try RSAService(n: n, e: "AQAB", d: d, header: headers)
    }
    try services.register(jwtProvider)

    // Create a router,
    // register all the app's routes to it,
    // and register the router with the app.
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Register middleware with the app's services.
    // These middleware will automaticly be added to all routes.
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(CORSMiddleware()) // Adds Cross-Origin-Request headers to all responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a MySQL database.
    var dbConfig = DatabasesConfig()
    try databases(config: &dbConfig, for: env)
    services.register(dbConfig)

    // Configure migrations.
    // Add all models to the migration config so the `FluentProvider` will create tables for them in the database.
    var migrationConfig = MigrationConfig()
    try migrations(config: &migrationConfig)
    services.register(migrationConfig)
    
    // Register the `revert` command with service,
    // used to drop the database.
    var commands = CommandConfig.default()
    commands.useFluentCommands()
    services.register(commands)
}
