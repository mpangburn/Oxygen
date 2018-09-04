//
//  Tuple.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Returns a function that applies the given transformation to each element of a homogenous 2-tuple.
/// - Parameter transform: The transformation to apply to each element of the tuple.
/// - Returns: A function that applies the given transformation to each element of a homogenous 2-tuple.
@inlinable
public func map<Input, Output>(
    _ transform: @escaping (Input) -> Output
) -> (Input, Input) -> (Output, Output) {
    return { (transform($0), transform($1)) }
}

/// Returns a function that applies the given transformation to each element of a homogenous 3-tuple.
/// - Parameter transform: The transformation to apply to each element of the tuple.
/// - Returns: A function that applies the given transformation to each element of a homogenous 3-tuple.
@inlinable
public func map<Input, Output>(
    _ transform: @escaping (Input) -> Output
) -> (Input, Input, Input) -> (Output, Output, Output) {
    return { (transform($0), transform($1), transform($2)) }
}
