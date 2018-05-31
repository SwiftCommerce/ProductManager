import FluentSQL

final class QueryDataDecoder<Database> where Database: QuerySupporting {
    var entity: String?
    init(_ database: Database.Type, entity: String? = nil) {
        self.entity = entity
    }
    func decode<D>(_ type: D.Type, from data: [QueryField: Database.QueryData]) throws -> D where D: Decodable {
        let decoder = _QueryDataDecoder<Database>(data: data, entity: entity)
        return try D.init(from: decoder)
    }
}

/// MARK: Private

fileprivate final class _QueryDataDecoder<Database>: Decoder where Database: QuerySupporting {
    var codingPath: [CodingKey] { return [] }
    var userInfo: [CodingUserInfoKey: Any] { return [:] }
    var data: [QueryField: Database.QueryData]
    var entity: String?
    init(data: [QueryField: Database.QueryData], entity: String?) {
        self.data = data
        self.entity = entity
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(_QueryDataKeyedDecoder<Key, Database>(decoder: self, entity: entity))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { throw unsupported() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { throw unsupported() }
}

private func unsupported() -> FluentError {
    return FluentError(
        identifier: "rowDecode",
        reason: "PostgreSQL rows only support a flat, keyed structure `[String: T]`",
        suggestedFixes: [
            "You can conform nested types to `PostgreSQLJSONType` or `PostgreSQLArrayType`. (Nested types must be `PostgreSQLDataCustomConvertible`.)"
        ],
        source: .capture()
    )
}


fileprivate struct _QueryDataKeyedDecoder<K, Database>: KeyedDecodingContainerProtocol
    where K: CodingKey, Database: QuerySupporting
{
    var allKeys: [K] {
        return decoder.data.keys.compactMap { K(stringValue: $0.name) }
    }
    var codingPath: [CodingKey] { return [] }
    let decoder: _QueryDataDecoder<Database>
    var entity: String?
    init(decoder: _QueryDataDecoder<Database>, entity: String?) {
        self.decoder = decoder
        self.entity = entity
    }
    
    func _value(forEntity entity: String?, atField field: String) -> Database.QueryData? {
        guard let entity = entity else {
            return decoder.data.firstValue(forField: field)
        }
        return decoder.data.value(forEntity: entity, atField: field) ?? decoder.data.firstValue(forField: field)
    }
    
    func _parse<T>(_ type: T.Type, forKey key: K) throws -> T? {
        guard let data = _value(forEntity: entity, atField: key.stringValue)  else {
            return nil
        }
        
        return try Database.queryDataParse(T.self, from: data)
    }
    
    func contains(_ key: K) -> Bool { return decoder.data.keys.contains { $0.name == key.stringValue } }
    func decodeNil(forKey key: K) throws -> Bool { return _value(forEntity: entity, atField: key.stringValue) == nil }
    func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? { return try _parse(Int.self, forKey: key) }
    func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? { return try _parse(Int8.self, forKey: key) }
    func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? { return try _parse(Int16.self, forKey: key) }
    func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? { return try _parse(Int32.self, forKey: key) }
    func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? { return try _parse(Int64.self, forKey: key) }
    func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {  return try _parse(UInt.self, forKey: key) }
    func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? { return try _parse(UInt8.self, forKey: key) }
    func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? { return try _parse(UInt16.self, forKey: key) }
    func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? { return try _parse(UInt32.self, forKey: key) }
    func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? { return try _parse(UInt64.self, forKey: key) }
    func decodeIfPresent(_ type: Double.Type, forKey key: K) throws -> Double? { return try _parse(Double.self, forKey: key) }
    func decodeIfPresent(_ type: Float.Type, forKey key: K) throws -> Float? { return try _parse(Float.self, forKey: key) }
    func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? { return try _parse(Bool.self, forKey: key) }
    func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? { return try _parse(String.self, forKey: key) }
    func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T: Decodable { return try _parse(T.self, forKey: key) }
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        guard let t = try _parse(T.self, forKey: key) else {
            throw FluentError(identifier: "missingValue", reason: "No value found for key: \(key)", source: .capture())
        }
        return t
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey : CodingKey { return try decoder.container(keyedBy: NestedKey.self) }
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer { return try decoder.unkeyedContainer() }
    func superDecoder() throws -> Decoder { return decoder }
    func superDecoder(forKey key: K) throws -> Decoder { return decoder }
}

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
        return connector.databaseConnection(to: .mysql).flatMap(to: [[MySQLColumn : MySQLData]].self) { connection in
            connection.log(query: query, with: parameters)
            return connection.query(query, parameters)
        }.map(to: [Self].self, { (data) in
            return try data.map({ row -> Self in
                let genericData: [QueryField: MySQLData] = row.reduce(into: [:]) { row, cell in
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
