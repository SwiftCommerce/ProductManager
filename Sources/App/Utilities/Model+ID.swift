extension Model {
    
    /// Gets the model's ID as a future so you can chain it with `.map` and it doesn't throw.
    ///
    /// - Returns: The model's ID wrapped in a future.
    func assertID() -> Future<Self.ID> {
        // Create a new future with the static `Future.map` mthod.
        return Future.map({
            
            // Get the model's ID or throw an error.
            // The error is caught by the future and causes it to fail.
            return try self.requireID()
        })
    }
}
