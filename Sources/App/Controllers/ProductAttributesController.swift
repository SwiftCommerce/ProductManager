
import Vapor
import Fluent

/// A controller for all API endpoints that make operations on a product's attributes.
final class ProductAttributesController: RouteCollection {
    
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
        
        // Get the `Product` model from the route path, get all of the `Attribute` models connected to it, and return them.
        return try request.parameters.next(Product.self).flatMap(to: [AttributeContent].self, { try $0.attributes.response(on: request) })
    }
    
    /// Get an `Attribute` connected to a `Product` with a specified ID.
    func show(_ request: Request)throws -> Future<AttributeContent> {
        
        // Get the `Int` parameter from the request's path.
        let id = try request.parameters.next(Int.self)
        
        // Get the `Product` model specified in the route path.
        return try request.parameters.next(Product.self).flatMap(to: [AttributeContent].self) { (product) in
            
            // Get the first attribute with the `Int` parameter as it's ID from all attributes connected to the product.
            return try product.attributes.response(on: request, pivotQuery: ProductAttribute.query(on: request).filter(\.attributeID == id))
            
            // Gets the first element of the array (there should only be one or zero elements) and unwrap it.
        }.map(to: AttributeContent?.self, { $0.first }).unwrap(or: Abort(.notFound, reason: "No attribute connected to product with ID '\(id)'"))
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
        
        // Get the `Paroduct` and `Attribute` models passed into the request's route parameters.
        return try flatMap(request.parameters.next(Product.self), request.parameters.next(Attribute.self), { (product, attribute) in
            
            // Get the prodcut's attributes, and detach the attribute passed in.
            return product.attributes.detach(attribute, on: request).transform(to: .noContent)
        })
    }
}


