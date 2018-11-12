/// A request body used to update a `Category` model.
struct CategoryUpdateBody: Content {
    
    /// The IDs of the categories to attach to the parent category through a `CategoryPivot`.
    let attach: [Category.ID]?
    
    /// The IDs of the categories to detach from the parent category that are attached through pivots.
    let detach: [Category.ID]?
    
    /// A new value for the category's `sort` property.
    let sort: Int?
}

/// A controller for API endpoints that make operations on the `Category` model.
final class CategoryController: RouteCollection {
    
    /// Required by the `RouteCollection` protocol.
    /// Allows you to run this to add your routes to a router:
    ///
    ///     router.register(collection: CategoryController())
    ///
    /// - parameter router: The router that the controller's routes will be added to.
    func boot(router: Router) throws {
        
        // Create a router group, because all routes in this controller have the same parent path.
        let categories = router.grouped("categories")
        
        // Registers a POST endpoint at `/categories`.
        // The route automatically decodes the request's body to a `Category` model.
        categories.post(Category.self, use: create)
        
        // Registers a GET endpoint at `/categories`.
        categories.get(use: index)
        
        // Registers a GET endpoint at `/categories/:category`.
        categories.get(Category.parameter, use: show)
        
        // Registers a PATCH endpoint at `/categories/:category`.
        // The route automatically decodes the request's body to a `CategoryUpdateBody` object.
        categories.patch(CategoryUpdateContent.self, at: Category.parameter, use: update)
        
        // Registers a DELETE endpoint at `/categories/:category`.
        categories.delete(Category.parameter, use: delete)
    }
    
    /// Creates a new `Category` model.
    func create(_ request: Request, category: Category)throws -> Future<CategoryResponseBody> {
        
        // Get the category decoded from the request, save the category to the database, and convert it to a `CategoryResponseBody`.
        return category.save(on: request).response(on: request)
    }
    
    /// Get all `Category` models from the database.
    func index(_ request: Request)throws -> Future<[CategoryResponseBody]> {
        
        // Fetch all categories from the database.
        return Category.query(on: request).filter(\.isMain == true).sort(\.sort, .ascending).all().each(to: CategoryResponseBody.self, transform: { (category) in
            
            // Convert all categories to `CategoryResponseBody`s and return them.
            return Promise(category: category, on: request).futureResult
        })
    }
    
    /// Get a single `Category` model with a given ID.
    func show(_ request: Request)throws -> Future<CategoryResponseBody> {
        
        /// Get the `Category` model passed into the request's route parameters and convert it to a `CategoryResponseBody`.
        return try request.parameters.next(Category.self).response(on: request)
    }
   
    /// Updates the sub-categories of a given `Category` model.
    func update(_ request: Request, _ content: CategoryUpdateContent)throws -> Future<CategoryResponseBody> {
        
        // Get the category to update from route parameters.
        let category = try request.parameters.next(Category.self)
        
        // Update the category's propertys and save it to the database.
        return category.map(content.update).save(on: request).response(on: request)
    }
    
    /// Deletes a category from the database, along with its connections to other categories and products.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the category in the request's route parameters.
        return try request.parameters.next(Category.self).flatMap(to: Category.self, { (category) in
            
            // Delete all connections to category from products and categories.
            let detachCategories = try category.subCategories.pivots(on: request).delete()
            let detachProducts = try category.products.pivots(on: request).delete()
            
            // Once the connections to sud-catefories have been updated,
            // return the category from the parameter
            return [detachCategories, detachProducts].flatten(on: request).transform(to: category)
        }).flatMap(to: HTTPStatus.self, { (cateogory) in
            
            // All the connections are deleted, so now it is safe to delete the parent category from the database.
            return cateogory.delete(on: request).transform(to: .noContent)
        })
    }
}
