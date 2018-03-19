import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    try router.register(collection: ProductController())
    try router.register(collection: CategoryController())
    try router.register(collection: TranslationController())
    try router.register(collection: AttributesController())
}
