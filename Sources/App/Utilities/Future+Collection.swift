/// Extends `Future` if it wraps an object conforming to `Collection`.
extension Future where T: Collection {
    
    /// Calls `.map` on the result of the future.
    ///
    /// - Parameters:
    ///   - to: The return type of the method called on each collection element.
    ///   - transform: The method to call on the elements in the collection.
    /// - Returns: An array of the results of the `transform` method passed in, wrapped in a future.
    func loop<R>(to: R.Type, transform: @escaping (T.Element)throws -> Future<R>) -> Future<[R]> {
        return self.flatMap(to: [R].self, { (sequence) in
            return try sequence.map(transform).flatten()
        })
    }
}

