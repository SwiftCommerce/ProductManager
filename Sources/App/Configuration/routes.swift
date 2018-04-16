/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    
    // Register all the controllers with the application's router.
    try router.register(collection: PriceController())
    try router.register(collection: ProductController())
    try router.register(collection: CategoryController())
    try router.register(collection: AttributesController())
    try router.register(collection: TranslationController())
}
