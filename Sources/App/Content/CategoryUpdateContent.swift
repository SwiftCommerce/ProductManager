import Vapor

struct CategoryUpdateContent: Content {
    let name: String?
    let sort: Int?
    let isMain: Bool?
    
    func update(category: Category) -> Category {
        category.name = self.name ?? category.name
        category.sort = self.sort ?? category.sort
        category.isMain = self.isMain ?? category.isMain
        
        return category
    }
}
