import FluentMySQL
import Vapor

/// Handles interactions with the `Attribute` models
/// separatly from their connection to a product.
final class AttributeController: RouteCollection {
    
    /// Registers the route handlers to a
    /// given route path.
    ///
    /// This method is required by the
    /// `RouteCollection` protocol
    ///
    /// - Parameter router: The router the register
    ///   the route handlers with.
    func boot(router: Router) {
        let attributes = router.grouped("attributes")
        
        attributes.post(Attribute.self, use: create)
        attributes.get(use: index)
        attributes.get(Attribute.parameter, use: show)
        attributes.patch(AttributeBody.self, at: Attribute.parameter, use: update)
        attributes.delete(Attribute.parameter, use: delete)
    }
    
    /// Decodes an `Attribute` model from a request body
    /// and saves it to the database.
    func create(_ request: Request, _ attribute: Attribute)throws -> Future<Attribute> {
        return attribute.save(on: request)
    }
    
    /// Gets all `Attribute` models from the database.
    func index(_ request: Request)throws -> Future<[Attribute]> {
        return Attribute.query(on: request).all()
    }
    
    /// Gets a single `Attribute` model based on its ID.
    func show(_ request: Request)throws -> Future<Attribute> {
        return try request.parameters.next(Attribute.self)
    }
    
    /// Updates the properties of a single `Attribute` model,
    /// fetched by its ID, using dsts optional data from the
    /// request body. The database instance is then updated.
    func update(_ request: Request, _ body: AttributeBody)throws -> Future<Attribute> {
        return try request.parameters.next(Attribute.self).flatMap(to: Attribute.self) { attribute in
            
            // If the body's property has a value, set the
            // model's value, otherwise keep the model's
            // original value.
            attribute.name = body.name ?? attribute.name
            attribute.type = body.type ?? attribute.type
            
            return attribute.update(on: request)
        }
    }
    
    /// Delete a single `Attribute` model with a specific ID.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the model with the ID from the route, delete it, then return a 204 (No Content) status code.
        return try request.parameters.next(Attribute.self).delete(on: request).transform(to: .noContent)
    }
}

/// Used to update the properties of
/// an `Attribute` model in the
/// `AttributeController.update` route handler.
struct AttributeBody: Content {
    let name: String?
    let type: String?
}
