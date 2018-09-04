//
//  MutableCollection.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/3/18.
//

extension MutableCollection {
    /// Mutates each element in the collection.
    /// - Parameter mutate: The function used to mutate each element.
    @inlinable
    public mutating func mutateEach(_ mutate: (inout Element) -> Void) {
        for index in indices {
            mutate(&self[index])
        }
    }
}
