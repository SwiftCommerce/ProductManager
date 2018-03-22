/// A request body used to update a `Category` model.
struct CategoryUpdateBody: Content {
    
    /// The IDs of the categories to attach to the parent category through a `CategoryPivot`.
    let attach: [Category.ID]?
    
    /// The IDs of the categories to detach from the parent category that are attached through pivots.
    let detach: [Category.ID]?
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
        categories.post(use: create)
        
        // Registers a GET endpoint at `/categories`.
        categories.get(use: index)
        
        // Registers a GET endpoint at `/categories/:category`.
        categories.get(Category.parameter, use: show)
        
        // Registers a PATCH endpoint at `/categories/:category`.
        // The route automatically decodes the request's body to a `CategoryUpdateBody` object.
        categories.patch(CategoryUpdateBody.self, at: Category.parameter, use: update)
        
        // Registers a DELETE endpoint at `/categories/:category`.
        categories.delete(Category.parameter, use: delete)
    }
    
    /// Creates a new `Category` model.
    func create(_ request: Request)throws -> Future<CategoryResponseBody> {
        
        // Get the value of the `name` key from the request's body.
        let name = request.content.get(String.self, at: "name")
        
        // Create a new category with the name from the request, save the category to the database, and convert it to a `CategoryResponseBody`.
        return name.map(to: Category.self, { Category(name: $0) }).save(on: request).response(with: request)
    }
    
    /// Get all `Category` models from the database.
    func index(_ request: Request)throws -> Future<[CategoryResponseBody]> {
        
        // Fetch all categories from the database.
        return Category.query(on: request).all().flatMap(to: [CategoryResponseBody].self, { (categories) in
            
            // Convert all categories to `CategoryResponseBody`s and return them.
            categories.map({ Future(category: $0, executedWith: request) }).flatten()
        })
    }
    
    /// Get a single `Category` model with a given ID.
    func show(_ request: Request)throws -> Future<CategoryResponseBody> {
        
        /// Get the `Category` model passed into the request's route parameters and convert it to a `CategoryResponseBody`.
        return try request.parameter(Category.self).response(with: request)
    }
   
    /// Updates the sub-categories of a given `Category` model.
    func update(_ request: Request, _ categories: CategoryUpdateBody)throws -> Future<CategoryResponseBody> {
        
        // Get categories from the database with IDs that appear in `categories` properties.
        let attach = Category.query(on: request).all(where: \.id, in: categories.attach)
        let detach = Category.query(on: request).all(where: \.id, in: categories.detach)
        
        // Get the category to update from route parameters.
        let category = try request.parameter(Category.self)
        
        
        return Async.flatMap(to: Category.self, category, attach, detach) { (category, attach, detach) in
            
            // Detach all categories from parent category id `detach` array.
            let detached = detach.map({ category.subCategories.detach($0, on: request) }).flatten()
            
            // Attach all categories to parent category with an ID in the `attach` array.
            // We don't use `categories.subCategories.attach` because we gett weird compiler errors when we do.
            let attached = try attach.map({ try CategoryPivot(category, $0).save(on: request) }).flatten().transform(to: ())
            
            // Once attaching and detaching are complete, return the category that we updated.
            return [detached, attached].flatten().transform(to: category)
        }.response(with: request)
    }
    
    /// Deletes a category from the database, along with its connections to other categories and products.
    func delete(_ request: Request)throws -> Future<HTTPStatus> {
        
        // Get the category in the request's route parameters.
        return try request.parameter(Category.self).flatMap(to: Category.self, { (category) in
            
            // Delete all connections to category from products and categories.
            let detachCategories = category.subCategories.deleteConnections(on: request)
            let detachProducts = category.products.deleteConnections(on: request)
            
            // Once the connections to sud-catefories have been updated,
            // return the category from the parameter
            return [detachCategories, detachProducts].flatten().transform(to: category)
        }).flatMap(to: HTTPStatus.self, { (cateogory) in
            
            // All the connections are deleted, so now it is safe to delete the parent category from the database.
            return cateogory.delete(on: request).transform(to: .noContent)
        })
    }
}
