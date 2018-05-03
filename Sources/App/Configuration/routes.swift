/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    
    // Allows passing in a version path to the route
    // which is used by ths host's load balancer to
    // direct to the correct services, while at the
    // same time allowing us to ignore the value.
    let versioned = router.grouped(any)
    
    // Register all the controllers with the application's router.
    try versioned.register(collection: PriceController())
    try versioned.register(collection: ProductController())
    try versioned.register(collection: CategoryController())
    try versioned.register(collection: AttributeController())
    try versioned.register(collection: TranslationController())
    try versioned.register(collection: ProductAttributesController())
}
