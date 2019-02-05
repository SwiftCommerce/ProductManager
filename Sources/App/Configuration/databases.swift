import FluentMySQL

func databases(config: inout DatabasesConfig, for env: Environment)throws {
    if !env.isRelease {
        config.enableLogging(on: .mysql)
    }
    
    // Configure the MySQL Database.
    // If we are in Vapor Cloud, we use the available env vars,
    // otherwise we use the values for local development
    let mysql = MySQLDatabaseConfig.init(
        hostname: Environment.get("DATABASE_HOSTNAME") ?? "localhost",
        port: 3306,
        username: Environment.get("DATABASE_USER") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database:  Environment.get("DATABASE_DB") ?? "product_manager",
        transport: env.isRelease ? .cleartext : .unverifiedTLS
    )
    config.add(database: MySQLDatabase(config: mysql), as: .mysql)
}
