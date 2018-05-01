import FluentSQL

extension QueryBuilder {
    
    /// Gets all models from a table that have any one of a list of values in a specefied column.
    ///
    /// - Parameters:
    ///   - field: The column to check for a given value in.
    ///   - values: The values to check for in the columns.
    /// - Returns: All the models that match the given query, wrapped in a future.
    @discardableResult
    public func models<Value>(where field: KeyPath<Model, Value>, in values: [Value]?) -> Future<[Result]> where Value: ReflectionDecodable {
        
        // This method is different because we allow `nil` to be passed in instead of an array.
        // If we get `nil` instead of an array, return an empty array immediately, it saves time.
        guard let values = values else {
            return self.connection.eventLoop.newSucceededFuture(result: [])
        }
        
        // Wrap filter in `flatMap` so the method doesn't have to throw.
        // Since `value` is not `nil`, run the filter and get all the resulting models.
        return Future.flatMap(on: self.connection.eventLoop) { return try self.filter(field ~~ values).all() }
    }
}

extension Model {

    /// Allows you to run raw queries in a model type.
    /// The data from the query is decoded to the type the method is called on.
    ///
    /// - Parameters:
    ///   - query: The query to run on the database.
    ///   - parameters: Replacement values for `?` placeholders in the query.
    ///   - connector: The object to create a connection to the database with.
    /// - Returns: An array of model instances created from the fetched data, wrapped in a future.
    static func raw(_ query: String, with parameters: [MySQLDataConvertible] = [], on connector: DatabaseConnectable) -> Future<[Self]> {

        // I would document this, but I hope it get Sherlocked by Fluent.
        return connector.databaseConnection(to: .mysql).flatMap(to: [[MySQLColumn : MySQLData]].self) { (connection) in
            connection.log(query: query, with: parameters)
            return connection.query(query, parameters)
        }.map(to: [Self].self, { (data) in
            return try data.map({ row -> Self in
                let genericData: [QueryField: MySQLData] = row.reduce(into: [:]) { (row, cell) in
                    row[QueryField(entity: cell.key.table, name: cell.key.name)] = cell.value
                }
                return try QueryDataDecoder(MySQLDatabase.self, entity: Self.entity).decode(Self.self, from: genericData)
            })
        })
    }
}

extension MySQLConnection {
    
    /// A generic logging method for outputting raw queries and
    /// its parameters to the console if the connection has logging enabled.
    ///
    /// - Parameters:
    ///   - query: The database query that is run on the connection.
    ///   - parameters: The paramaters that are passed into the query
    ///     for replacement values.
    func log(query: String, with parameters: [MySQLDataConvertible]) {
        do {
            
            // If database logging is enabled, the connection will have a logger.
            if let logger = self.logger {
                
                // Create a formatted message with the query, parameters, and timestamp.
                let log = DatabaseLog(
                    dbuid: "mysql",
                    query: query,
                    values: try parameters.map { try $0.convertToMySQLData().description }
                )
                
                // Log the message.
                logger.record(query: log.description)
            }
        } catch {
            // Converting the paramaters passed in to `MySQLData` failed. Signify the failure to log.
            print(DatabaseLog(dbuid: "mysql", query: "Logging failed. Unable to get parameter descriptions."))
        }
    }
}
