import Async
import Dispatch
import Fluent
import Foundation

extension Benchmarker where Database: QuerySupporting & TransactionSupporting {
    /// The actual benchmark.
    fileprivate func _benchmark(on conn: Database.Connection) throws {
        // create
        let tanner = User<Database>(name: "Tanner", age: 23)
        _ = try test(tanner.save(on: conn))

        do {
            _ = try Database.transaction(on: conn) { conn in
                let user = User<Database>(name: "User #1", age: 1)
                return user.save(on: conn).flatMap(to: Void.self) { _ in
                    return conn.query(User<Database>.self).count().map(to: Void.self) { count in
                        if count != 2 {
                            self.fail("count \(count) != 2")
                        }

                        throw FluentBenchmarkError(identifier: "test", reason: "rollback", source: .capture())
                    }
                }

            }.wait()
        } catch is FluentBenchmarkError {
            // expected
        }

        let count = try test(conn.query(User<Database>.self).count())
        if count != 1 {
            self.fail("count must have been restored to one")
            return
        }
    }

    /// Benchmark fluent transactions.
    public func benchmarkTransactions() throws {
        let conn = try test(pool.requestConnection())
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}

extension Benchmarker where Database: QuerySupporting & TransactionSupporting & SchemaSupporting {
    /// Benchmark fluent transactions.
    /// The schema will be prepared first.
    public func benchmarkTransactions_withSchema() throws {
        let conn = try test(pool.requestConnection())
        try test(UserMigration<Database>.prepare(on: conn))
        defer {
            try? test(UserMigration<Database>.revert(on: conn))
        }
        try self._benchmark(on: conn)
        pool.releaseConnection(conn)
    }
}
