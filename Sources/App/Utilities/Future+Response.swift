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

extension Future where T: Collection {
    func loop<R>(to: R.Type, transform: @escaping (T.Element)throws -> R) -> Future<[R]> {
        return self.map(to: [R].self, { (sequence) in
            return try sequence.map(transform)
        })
    }
    
    func loop<R>(to: R.Type, transform: @escaping (T.Element)throws -> Future<R>) -> Future<[R]> {
        return self.flatMap(to: [R].self, { (sequence) in
            return try sequence.map(transform).flatten()
        })
    }
}
