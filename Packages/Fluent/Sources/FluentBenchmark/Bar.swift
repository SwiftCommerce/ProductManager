import Async
import Fluent
import Foundation

struct Bar<D>: Model, SoftDeletable, Timestampable where D: QuerySupporting {
    /// See Model.Database
    typealias Database = D

    /// See Model.ID
    typealias ID = UUID

    /// See Model.name
    static var name: String { return "bar" }

    /// See Model.idKey
    static var idKey: IDKey { return \.id }

    /// See `Timestampable.createdAtKey`
    static var createdAtKey: CreatedAtKey {
        return \.createdAt
    }

    /// See `Timestampable.updatedAtKey`
    static var updatedAtKey: UpdatedAtKey {
        return \.updatedAt
    }

    /// See `SoftDeletable.deletedAtKey`
    static var deletedAtKey: DeletedAtKey {
        return \.deletedAt
    }

    /// Foo's identifier
    var id: UUID?

    /// Test integer
    var baz: Int

    /// See `Timestampable.createdAt`
    var createdAt: Date?

    /// See `Timestampable.updatedAt`
    var updatedAt: Date?

    /// See `SoftDeletable.deletedAt`
    var deletedAt: Date?

    /// Create a new foo
    init(id: ID? = nil, baz: Int) {
        self.id = id
        self.baz = baz
    }
}

extension Bar: Migration where D: SchemaSupporting { }
