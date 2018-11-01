import Vapor

/// A representation of a request's body when you need to update a `Price` model.
struct PriceUpdateBody: Content {
    
    ///
    let cents: Int?
    
    ///
    let activeFrom: Date?
    
    ///
    let activeTo: Date?
    
    ///
    let active: Bool?
}

extension Price {
    
    /// Updates the model's properties with data from a request.
    ///
    /// - Parameter body: The body of a request, decoded to a `PriceUpdateBody`.
    /// - Returns: The updated `Price` instance.
    func update(with body: PriceUpdateBody) -> Price {
        
        // Update all the properties if a value for it is found in the body, else use the old value.
        self.cents = body.cents ?? self.cents
        self.activeFrom = body.activeFrom ?? self.activeFrom
        self.activeTo = body.activeTo ?? self.activeTo
        self.active = body.active ?? self.active
        
        return self
    }
}
