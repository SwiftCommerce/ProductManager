import Async
import Dispatch
import Fluent
import Foundation

extension Benchmarker where Database: JoinSupporting & ReferenceSupporting & QuerySupporting {
    /// The actual benchmark.
    fileprivate func _benchmark(on conn: Database.Connection) throws {
        // create
        var tanner = User<Database>(name: "Tanner", age: 23)
        tanner = try test(tanner.save(on: conn))

        var ziz = try Pet<Database>(name: "Ziz", ownerID: tanner.requireID())
        ziz = try test(ziz.save(on: conn))


        var count = try test(tanner.pets.query(on: conn).count())
        if count != 1 {
            self.fail("invalid count \(count) != 1")
        }

        guard let ownerRelation = ziz.owner else {
            self.fail("owner relation nil")
            return
        }

        let owner = try test(ownerRelation.get(on: conn))
        if owner.name != "Tanner" {
            self.fail("pet owner's name wrong")
        }

        let originalID = tanner.id
        tanner.id = UUID() // change id
        tanner = try test(tanner.update(on: conn, originalID: originalID))

        count = try test(tanner.pets.query(on: conn).count())
        if count != 1 {
            self.fail("invalid count \(count) != 1")
        }

        do {
            guard let zizFetch = try test(Pet<Database>.query(on: conn).first()) else {
                fail("could not fetch pet")
                return
            }

            if zizFetch.ownerID == nil {
                fail("owner id was nil")
            }
        }

        try test(tanner.delete(on: conn))
        do {
            guard let zizFetch = try test(Pet<Database>.query(on: conn).first()) else {
                fail("could not fetch pet")
                return
            }

            if zizFetch.ownerID != nil {
                fail("owner id did not get nullified")
            }
        }
    }

    /// Benchmark fluent relations.
    public func benchmarkReferentialActions() throws {
        let conn = try test(pool.requestConnection())
        try test(Database.enableReferences(on: conn))
        try self._benchmark(on: conn)
        self.pool.releaseConnection(conn)
    }
}

extension Benchmarker where Database: SchemaSupporting & JoinSupporting & ReferenceSupporting & QuerySupporting {
    /// Benchmark fluent relations.
    /// The schema will be prepared first.
    public func benchmarkReferentialActions_withSchema() throws {
        let conn = try test(pool.requestConnection())
        try test(Database.enableReferences(on: conn))
        try test(UserMigration<Database>.prepare(on: conn))
        try test(Pet<Database>.prepare(on: conn))
        do {
            try self._benchmark(on: conn)
        } catch {
            fail("\(error)")
        }
        try test(Pet<Database>.revert(on: conn))
        try test(UserMigration<Database>.revert(on: conn))
        self.pool.releaseConnection(conn)
    }
}


