/// Describes a relational join which brings columns of data from multiple entities into one response.
///
/// A = (id, name, b_id)
/// B = (id, foo)
///
/// A join B = (id, b_id, name, foo)
///
/// joinedKey = A.b_id
/// baseKey = B.id
public struct QueryJoin {
    /// Join type.
    /// See QueryJoinMethod.
    public let method: QueryJoinMethod

    /// Table/collection that will be accepting the joined data
    ///
    /// The key from the base table that will be compared to the key from the joined table during the join.
    ///
    /// base        | joined
    /// ------------+-------
    /// <baseKey>   | base_id
    public let base: QueryField

    /// table/collection that will be joining the base data
    ///
    /// The key from the joined table that will be compared to the key from the base table during the join.
    ///
    /// base | joined
    /// -----+-------
    /// id   | <joined_key>
    public let joined: QueryField

    /// Create a new Join
    public init(method: QueryJoinMethod, base: QueryField, joined: QueryField) {
        self.method = method
        self.base = base
        self.joined = joined
    }
}

/// An exhaustive list of
/// possible join types.
public enum QueryJoinMethod {
    /// returns only rows that appear in both sets
    case inner
    /// returns all matching rows from the queried table _and_ all rows that appear in both sets
    case outer
}

// MARK: Support

public protocol JoinSupporting: Database { }

// MARK: Query

extension DatabaseQuery {
    /// Joined models.
    public var joins: [QueryJoin] {
        get { return extend["joins"] as? [QueryJoin] ?? [] }
        set { extend["joins"] = newValue }
    }
}

// MARK: Join on Model.ID

extension QueryBuilder where Model.Database: JoinSupporting {
    /// Join another model to this query builder.
    public func join<Joined>(
        _ joinedType: Joined.Type = Joined.self,
        field joinedKey: KeyPath<Joined, Model.ID>,
        to baseKey: KeyPath<Model, Model.ID?> = Model.idKey,
        method: QueryJoinMethod = .inner
    ) throws -> Self where Joined: Fluent.Model {
        let join = try QueryJoin(
            method: method,
            base: baseKey.makeQueryField(),
            joined: joinedKey.makeQueryField()
        )
        query.joins.append(join)
        return self
    }

    /// Join another model to this query builder.
    public func join<Joined>(
        _ joinedType: Joined.Type = Joined.self,
        field joinedKey: KeyPath<Joined, Model.ID?>,
        to baseKey: KeyPath<Model, Model.ID?> = Model.idKey,
        method: QueryJoinMethod = .inner
    ) throws -> Self where Joined: Fluent.Model {
        let join = try QueryJoin(
            method: method,
            base: baseKey.makeQueryField(),
            joined: joinedKey.makeQueryField()
        )
        query.joins.append(join)
        return self
    }

    /// Join another model to this query builder.
    public func join<Joined>(
        _ joinedType: Joined.Type = Joined.self,
        field joinedKey: KeyPath<Joined, Model.ID?>,
        to baseKey: KeyPath<Model, Model.ID>,
        method: QueryJoinMethod = .inner
    ) throws -> Self where Joined: Fluent.Model {
        let join = try QueryJoin(
            method: method,
            base: baseKey.makeQueryField(),
            joined: joinedKey.makeQueryField()
        )
        query.joins.append(join)
        return self
    }

    /// Join another model to this query builder.
    public func join<Joined>(
        _ joinedType: Joined.Type = Joined.self,
        field joinedKey: KeyPath<Joined, Model.ID>,
        to baseKey: KeyPath<Model, Model.ID>,
        method: QueryJoinMethod = .inner
    ) throws -> Self where Joined: Fluent.Model {
        let join = try QueryJoin(
            method: method,
            base: baseKey.makeQueryField(),
            joined: joinedKey.makeQueryField()
        )
        query.joins.append(join)
        return self
    }
}
