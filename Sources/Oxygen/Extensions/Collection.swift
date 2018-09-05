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

    /// Returns `true` if the collection contains more than `limit` elements.
    /// - Parameter limit: The number of elements to test for containment.
    /// - Returns: A Boolean value describing whether the number of elements in the collection
    ///            excedes the given limit.
    @inlinable
    public func countExcedes(_ limit: Int) -> Bool {
        // TODO: This is less efficient than accessing `count` directly
        //       for implementations of RandomAccessCollection,
        //       but we need dynamic dispatch to achieve that.
        //       Would make a good SE proposal.
        var count = 0
        for _ in self {
            if count > limit {
                return true
            }
            count += 1
        }
        return false
    }
}
