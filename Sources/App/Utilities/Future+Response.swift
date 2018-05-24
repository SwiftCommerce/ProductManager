// The methods below convert a model to a struct the represents the model.
// They take in an object that conforms to `DatabaseConnectable` so they can get related models.

/// Exend `Future` if it wraps a `Category` model.
extension Future where T == Category {
    
    /// Create a publicizable represention of the wrapped model, appropriate for returning as JSON.
    ///
    /// - Parameter executor: An object that can be used to query a model's table.
    /// - Returns: A future wrapping the public representation of the wrapped object.
    func response(on request: Request) -> Future<CategoryResponseBody> {
        return self.flatMap(to: CategoryResponseBody.self) { this in
            return Promise<CategoryResponseBody>(category: this, on: request).futureResult
        }
    }
}

/// Extend `Future` if it wraps a `Product` model.
extension Future where T == Product {
    
    /// Create a publicizable represention of the wrapped model, appropriate for returning as JSON.
    ///
    /// - Parameter executor: An object that can be used to query a model's table.
    /// - Returns: A future wrapping the public representation of the wrapped object.
    func response(on request: Request) -> Future<ProductResponseBody> {
        return self.flatMap(to: ProductResponseBody.self) { this in
            return Promise<ProductResponseBody>(product: this, on: request).futureResult
        }
    }
}

/// Extend `Future` if it wraps a model conforming to `Trnslation`.
extension Future where T: Translation {
    
    /// Create a publicizable represention of the wrapped model, appropriate for returning as JSON.
    ///
    /// - Parameter executor: An object that can be used to query a model's table.
    /// - Returns: A future wrapping the public representation of the wrapped object.
    func response(on request: Request) -> Future<TranslationResponseBody> {
        return self.flatMap(to: TranslationResponseBody.self) { this in
            return this.response(on: request)
        }
    }
}
