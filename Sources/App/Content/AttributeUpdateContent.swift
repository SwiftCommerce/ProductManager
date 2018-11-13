import Vapor

struct AttributeUpdateContent: Content {
    let value: String?
    
    func update(pivot: ProductAttribute) -> ProductAttribute {
        pivot.value = self.value ?? pivot.value
        return pivot
    }
}
