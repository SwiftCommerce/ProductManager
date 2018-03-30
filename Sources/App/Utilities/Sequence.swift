extension Sequence {
    func group<U>(by key: KeyPath<Iterator.Element, U>) -> [U: [Iterator.Element]] where U: Hashable {
        return Dictionary(grouping: self, by: { (element) in
            return element[keyPath: key]
        })
    }
}
