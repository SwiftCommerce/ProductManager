import Async
import Fluent
import Foundation

public final class User<D>: Model, Timestampable where D: QuerySupporting {
    /// See Model.Database
    public typealias Database = D

    /// See Model.ID
    public typealias ID = UUID

    /// See Model.idKey
    public static var idKey: IDKey { return \.id }

    /// See Timestampable.createdAtKey
    public static var createdAtKey: CreatedAtKey { return \.createdAt }

    /// See Timestampable.updatedAtKey
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }

    /// See Model.name
    public static var entity: String {
        return "users"
    }

    /// See Model.database
    public static var database: DatabaseIdentifier<D> {
        return .init("test")
    }

    /// Foo's identifier
    var id: UUID?

    /// Name string
    var name: String

    /// Age int
    var age: Int

    /// Timestampable.createdAt
    public var createdAt: Date?

    /// Timestampable.updatedAt
    public var updatedAt: Date?

    /// Create a new foo
    init(id: ID? = nil, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}

// MARK: Relations

extension User {
    /// A relation to this user's pets.
    var pets: Children<User, Pet<Database>> {
        return children(\.ownerID)
    }
}

// MARK: Migration

internal struct UserMigration<D>: Migration
    where D: QuerySupporting & SchemaSupporting
{
    /// See Migration.database
    typealias Database = D

    /// See Migration.prepare
    static func prepare(on connection: Database.Connection) -> Future<Void> {
        return Database.create(User<Database>.self, on: connection) { builder in
            try builder.field(for: \User<Database>.id)
            try builder.field(for: \User<Database>.name)
            try builder.field(for: \User<Database>.age)
            try builder.field(for: \User<Database>.createdAt)
            try builder.field(for: \User<Database>.updatedAt)
        }
    }

    /// See Migration.revert
    static func revert(on connection: Database.Connection) -> Future<Void> {
        return Database.delete(User<Database>.self, on: connection)
    }
}
