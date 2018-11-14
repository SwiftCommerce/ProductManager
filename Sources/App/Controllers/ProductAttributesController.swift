
import Vapor
import Fluent

/// A controller for all API endpoints that make operations on a product's attributes.
final class ProductAttributesController: RouteCollection {
    typealias Pivot = ProductAttribute
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: AttributeController())
    ///
    /// - parameter router: The router that the controller's routes will be added to.
    func boot(router: Router) throws {
        
        // Create a router group, because all routes in this controller have the same parent path.
        let attributes = router.grouped(Product.parameter, "attributes")
        
        // Registers a POST endpont at `products/:product/attributes`.
        // This route automaticly decodes the request's body to an `Attribute` model.
        attributes.post(AttributeConnection.self, use: create)
        
        // Registers a GET endpont at `products/:product/attributes`.
        attributes.get(use: index)
        
        // Register a GET endpoint at `products/:product/attributes/:int`.
        attributes.get(Attribute.parameter, use: show)
        
        // Register a PATCH endpoint at `/products/:product/attributes/:int`.
        attributes.patch(AttributeUpdateContent.self, at: Attribute.parameter, use: update)
        
        // Register a DELETE endpoint at `/prodcuts/:prodcut/attributes/:attributes`.
        attributes.delete(Attribute.parameter, use: delete)
    }
    
    /// Creates a new `Attribute` model from a request and saves it to the database.
    /// This route handler requires the router to decode the request's body to an `Attribute` and pass the model in with the request.
    func create(_ request: Request, _ content: AttributeConnection)throws -> Future<AttributeContent> {
        
        // Get the product the attribute will be connected to.
        let product = try request.parameters.id(for: Product.self)
        
        // Get the attribute to connect to the product from the `attributeID` key.
        let attribute = Attribute.find(content.attributeID, on: request).unwrap(or: Abort(.badRequest, reason: "No attribute for ID in body"))
        
        // Create the `ProductAttribute` pivot to connect the attribute to the product.
        let pivot = ProductAttribute(content, product: product).save(on: request)
        
        // Create a user-firendly response from the attribute and pivot and return it.
        return map(attribute, pivot, AttributeContent.init)
    }
    
    /// Fetches all the `Attribute` models connected to a `Product`.
    func index(_ request: Request)throws -> Future<[AttributeContent]> {
        
        // The `productID` value of all the `ProductAttribute` pivots to get.
        let product = try request.parameters.id(for: Product.self)
        
        // Get all the `ProductAttribute` and connected `Attribute` models that have the `Product` ID from the reset paramaters.
        let productID = \Pivot.productID
        let attributeID = \Pivot.attributeID
        let attributes = Attribute.query(on: request).join(attributeID, to: \Attribute.id).filter(productID == product).alsoDecode(Pivot.self).all()

        // Convert each `Attribute`/`ProductAttribute` pair into an `AttributeContent` instance.
        return attributes.map { attributes in attributes.map(AttributeContent.init) }
    }
    
    /// Get an `Attribute` connected to a `Product` with a specified ID.
    func show(_ request: Request)throws -> Future<AttributeContent> {
        
        // Get the specified `Product` model from the request's route parameters.
        let productID = try request.parameters.id(for: Product.self)
        
        // Get the ID of the attribute to update.
        let attributeID = try request.parameters.id(for: Attribute.self)
        
        // Get the `ProductAttribute` and `Attribute` models required to create a `AttributeContent` instance.
        let pivot = ProductAttribute.query(on: request).filter(\.productID == productID).filter(\.attributeID == attributeID).first()
        let attribute = Attribute.query(on: request).filter(\.id == attributeID).first()
        
        // Convert the pivot and attribute models to an `AttributeContent` instance if they both exist.
        let error = Abort(.notFound)
        return map(attribute.unwrap(or: error), pivot.unwrap(or: error), AttributeContent.init)
    }
    
    /// Updates an attribute's value.
    func update(_ request: Request, content: AttributeUpdateContent)throws -> Future<AttributeContent> {
        
        // Get the specified `Product` model from the request's route parameters.
        let product = try request.parameters.id(for: Product.self)
        
        // Get the ID of the attribute to update.
        let id = try request.parameters.id(for: Attribute.self)
        
        // Update the pivot's `value` property if a new value was passed into the request body.
        // Otherwise, just get the pivot.
        let query = ProductAttribute.query(on: request).filter(\.productID == product).filter(\.attributeID == id)
        if let value = content.value {
            _ = query.update(\.value, to: value)
        }
        let pivot = query.first()
        
        // Get the attribute that has the ID passed in and is connected to the product ID passed in.
        let productID = \ProductAttribute.productID
        let attributeID = \ProductAttribute.attributeID
        let attribute = Attribute.query(on: request).join(\Attribute.id, to: attributeID).filter(\.id == id).filter(productID == product).first()
        
        // Create a response body with the attribute and pivot data, including the type, name, and value of the attribute.
        let error = Abort(.notFound)
        return map(attribute.unwrap(or: error), pivot.unwrap(or: error), AttributeContent.init)
    }
    
    /// Detaches a given `Attribute` from its parent `Prodcut` model.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get `Prodduct` and `Attribute` IDs of the pivot to delete.
        let product = try request.parameters.id(for: Product.self)
        let attribute = try request.parameters.id(for: Attribute.self)
        
        // Delete all pivots that have matching `Product` and `Attribute` IDs.
        let delete = ProductAttribute.query(on: request).filter(\.productID == product).filter(\.attributeID == attribute).delete()
        
        // Return HTTP 204 (No Content) status.
        return delete.transform(to: .noContent)
    }
}


