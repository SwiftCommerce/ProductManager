import Fluent
import Vapor

/// A controller for all API endpoints that make operations on a product's attributes.
final class AttributesController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: AttributeController())
    ///
    /// - parameter router: The router that the controller's routes will be added to.
    func boot(router: Router) throws {
        
        // Create a router group, because all routes in this controller have the same parent path.
        let attributes = router.grouped("products", Product.parameter, "attributes")
        
        // Registers a POST endpont at `products/:product/attributes`.
        // This route automaticly decodes the request's body to an `Attribute` model.
        attributes.post(AttributeContent.self, use: create)
        
        // Registers a GET endpont at `products/:product/attributes`.
        attributes.get(use: index)
        
        // Register a GET endpoint at `products/:product/attributes/:int`.
        attributes.get(Attribute.parameter, use: show)
        
        // Register a PATCH endpoint at `/products/:product/attributes/:int`.
        attributes.patch(Int.parameter, use: update)
        
        // Register a DELETE endpoint at `/prodcuts/:prodcut/attributes/:attributes`.
        attributes.delete(Attribute.parameter, use: delete)
    }
    
    /// Creates a new `Attribute` model from a request and saves it to the database.
    /// This route handler requires the router to decode the request's body to an `Attribute` and pass the model in with the request.
    func create(_ request: Request, _ content: AttributeContent)throws -> Future<AttributeContent> {
        
        // Get the `Product` model from the route parameters.
        let parent = try request.parameter(Product.self)
        
        // Get the amount of attributes that already exist in the database with the name of the new attribute.
        let attributeCount = parent.flatMap(to: Int.self) { (product) in
            return try product.attributes.query(on: request).filter(\.name == content.name).count()
        }
        
        let attribute = flatMap(to: Attribute.self, attributeCount, parent) { (attributeCount, parent) in
            
            // Verify that there are less then one (0 or fewer) attributes already in the database with the name passed in.
            guard attributeCount < 1 else {
                throw Abort(.badRequest, reason: "Attribute already exists for product with name '\(content.name)'")
            }
            
            // Create the new attribute, Save it to the database, and return it from the route.
            return Attribute(name: content.name, type: content.value).save(on: request)
        }
        
        // Create a pivot between the parent product and the attribute, then return the attribute.
        return Async.flatMap(to: AttributeContent.self, attribute, parent) { attribute, product in
            let pivot = try ProductAttribute(value: content.value, language: content.language, product: product, attribute: attribute)
            let content = AttributeContent(attribute: attribute, pivot: pivot)
            return pivot.save(on: request).transform(to: content)
        }
    }
    
    /// Fetches all the `Attribute` models connected to a `Product`.
    func index(_ request: Request)throws -> Future<[AttributeContent]> {
        
        // Get the `Product` model from the route path, get all of the `Attribute` models connected to it, and return them.
        return try request.parameter(Product.self).flatMap(to: [AttributeContent].self, { try $0.attributes.response(on: request) })
    }
    
    /// Get an `Attribute` connected to a `Product` with a specified ID.
    func show(_ request: Request)throws -> Future<AttributeContent> {
        
        // Get the `Int` parameter from the request's path.
        let id = try request.parameter(Int.self)
        
        // Get the `Product` model specified in the route path.
        return try request.parameter(Product.self).flatMap(to: [AttributeContent].self) { (product) in
            
            // Get the first attribute with the `Int` parameter as it's ID from all attributes connected to the product.
            return try product.attributes.response(on: request, pivotQuery: ProductAttribute.query(on: request).filter(\.attributeID == id))
            
            // Gets the first element of the array (there should only be one or zero elements) and unwrap it.
        }.map(to: AttributeContent?.self, { $0.first }).unwrap(or: Abort(.notFound, reason: "No attribute connected to product with ID '\(id)'"))
    }
    
    /// Updates an attribute's value.
    func update(_ request: Request)throws -> Future<AttributeContent> {
        
        // Get the specified `Product` model from the request's route parameters.
        let product = try request.parameter(Product.self)
        
        // Get the ID of the attribute to update.
        let id = try request.parameter(Int.self)
        
        // Get the new value fore the for the `Attribute` model.
        let newValue = request.content.get(String.self, at: "value")
        
        // Return the result of the `flatMap` completion handler, which is fired after the two futures passed in have complete.
        return flatMap(to: Product.self, product, newValue, { (product, newValue) in
            
            // Find the attribute connected to the product with the ID passed in, update its `value` property, and return the product.
            return try product.attributes.query(on: request).filter(\Attribute.id == id).update(\Attribute.type, to: newValue).transform(to: product)
        }).flatMap(to: [AttributeContent].self, { product in
            
            // `QueryBuilder.update` returns `Future<Void>`, so to get the updated attribute, we need to run another query.
            return try product.attributes.response(on: request, pivotQuery: ProductAttribute.query(on: request).filter(\.attributeID == id))
            
            // Gets the first element of the array (there should only be one or zero elements) and unwrap it.
        }).map(to: AttributeContent?.self, { $0.first }).unwrap(or: Abort(.notFound, reason: "No attribute connected to product with ID '\(id)'"))
    }
    
    /// Detaches a given `Attribute` from its parent `Prodcut` model.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the `Paroduct` and `Attribute` models passed into the request's route parameters.
        return try flatMap(to: HTTPStatus.self, request.parameter(Product.self), request.parameter(Attribute.self), { (product, attribute) in
            
            // Get the prodcut's attributes, and detach the attribute passed in.
            return product.attributes.detach(attribute, on: request).transform(to: .noContent)
        })
    }
}


