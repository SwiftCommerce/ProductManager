extension Future where T == Category {
    func response(with executor: DatabaseConnectable) -> Future<CategoryResponseBody> {
        return self.flatMap(to: CategoryResponseBody.self, { this in
            return Future<CategoryResponseBody>(category: this, executedWith: executor)
        })
    }
}


extension Future where T == Product {
    func response(with executor: DatabaseConnectable) -> Future<ProductResponseBody> {
        return self.flatMap(to: ProductResponseBody.self, { this in
            return Future<ProductResponseBody>(product: this, executedWith: executor)
        })
    }
}

extension Future where T: Translation {
    func response(on executor: DatabaseConnectable) -> Future<TranslationResponseBody> {
        return self.flatMap(to: TranslationResponseBody.self, { (this) in
            return this.response(on: executor)
        })
    }
}
