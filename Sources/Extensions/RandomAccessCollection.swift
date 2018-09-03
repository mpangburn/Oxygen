//
//  RandomAccessCollection.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/2/18.
//

import class Dispatch.DispatchQueue


extension RandomAccessCollection {
    /// Concurrently performs a side effect on each element in the collection.
    /// - Parameter body: A side effect to run on each element.
    @inlinable
    public func concurrentForEach(_ body: (Element) -> Void) {
        DispatchQueue.concurrentPerform(iterations: count) { offset in
            let idx = index(startIndex, offsetBy: offset)
            body(self[idx])
        }
    }

    /// Concurrently maps a transformation over the collection.
    /// - Parameter transform: The transformation to apply to each element.
    /// - Returns: An array containing the transformed elements.
    @inlinable
    public func concurrentMap<NewElement>(
        _ transform: (Element) -> NewElement
    ) -> [NewElement] {
        let result = Atomic(Array<NewElement?>(repeating: nil, count: count))
        DispatchQueue.concurrentPerform(iterations: count) { offset in
            let idx = index(startIndex, offsetBy: offset)
            let transformed = transform(self[idx])
            result.modify { result in
                let idx = result.index(result.startIndex, offsetBy: offset)
                result[idx] = transformed
            }
        }
        return result.value.map { $0! }
    }
}
