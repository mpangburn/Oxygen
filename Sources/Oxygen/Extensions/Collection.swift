//
//  Collection.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/2/18.
//

extension Collection {
    /// Performs a side effect on each element in the collection.
    /// - Parameter body: A side effect to run on each element.
    /// - Returns: The collection.
    @inlinable
    public func withEach(_ body: (Element) throws -> Void) rethrows -> Self {
        try forEach(body)
        return self
    }
}
