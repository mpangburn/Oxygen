//
//  Array.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/2/18.
//

import class Dispatch.DispatchQueue


extension Array {
    /// Concurrently performs a side effect on each element in the array.
    /// - Parameter body: A side effect to run on each element.
    @inlinable
    public func concurrentForEach(_ body: (Element) -> Void) {
        DispatchQueue.concurrentPerform(iterations: count) { index in
            body(self[index])
        }
    }

    /// Concurrently maps a transformation over the array.
    /// - Parameter transform: The transformation to apply to each element.
    /// - Returns: An array containing the transformed elements.
    @inlinable
    public func concurrentMap<NewElement>(
        _ transform: (Element) -> NewElement
    ) -> [NewElement] {
        var result = Atomic(Array<NewElement?>(repeating: nil, count: count))
        DispatchQueue.concurrentPerform(iterations: count) { index in
            let transformed = transform(self[index])
            result.modify { $0[index] = transformed }
        }
        return result.value.map { $0! }
    }
}
