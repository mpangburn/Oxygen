//
//  Optional.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

extension Optional {
    /// Collapses the optional into a single value.
    /// - Parameter wrappedTransform: The transformation to apply if the value is present.
    /// - Parameter alternativeProvider: The output-providing autoclosure to invoke if the value is absent.
    /// - Returns: The transformed value if the value is present,
    ///            or the output of the alternative provider if the value is absent.
    @inlinable
    public func converge<Output>(
        ifSome wrappedTransform: (Wrapped) throws -> Output,
        ifNone alternativeProvider: @autoclosure () throws -> Output
    ) rethrows -> Output {
        switch self {
        case .some(let wrapped):
            return try wrappedTransform(wrapped)
        case .none:
            return try alternativeProvider()
        }
    }
}

extension Optional {
    /// Discards the wrapped value if it fails to pass the predicate.
    /// - Parameter shouldKeep: A closure determining whether the wrapped value should be kept.
    /// - Returns: The `Optional` instance unmodified if it passes the predicate and `nil` otherwise.
    @inlinable
    public func filter(
        _ shouldKeep: (Wrapped) throws -> Bool
    ) rethrows -> Optional {
        return try flatMap { try shouldKeep($0) ? $0 : nil }
    }

    /// Returns the given value combined with the wrapped value if the value is present,
    /// or the given value if the value is absent.
    /// - Parameter initialValue: The value to combine with the wrapped value, or to return if the value is absent.
    /// - Parameter combine: A closure combining the given value with the wrapped value.
    /// - Returns: The given value combined with the wrapped value if the value is present,
    ///            or the given value if the value is absent.
    @inlinable
    public func reduce<Output>(
        _ initialValue: Output,
        _ combine: (Output, Wrapped) throws -> Output
    ) rethrows -> Output {
        return try converge(
            ifSome: { try combine(initialValue, $0) },
            ifNone: initialValue
        )
    }
}

extension Optional {
    /// Performs a side-effect depending on the presence of the value.
    /// - Parameter someHandler: The handler to invoke if the value is present.
    /// - Parameter noneHandler: The handler to invoke if the value is absent.
    /// - Returns: The optional instance.
    @inlinable
    @discardableResult
    public func handle(
        ifSome someHandler: (Wrapped) throws -> Void,
        ifNone noneHandler: () throws -> Void
    ) rethrows -> Optional {
        try converge(ifSome: someHandler, ifNone: noneHandler())
        return self
    }

    /// Performs a side effect if the value is present.
    /// - Parameter body: The closure to invoke on the wrapped value, if present.
    /// - Returns: The optional instance.
    @inlinable
    @discardableResult
    public func ifSome(
        _ body: (Wrapped) throws -> Void
    ) rethrows -> Optional {
        return try handle(ifSome: body, ifNone: noop)
    }

    /// Performs a side effect if the value is absent.
    /// - Parameter body: The closure to invoke if the value is absent.
    /// - Returns: The optional instance.
    @inlinable
    @discardableResult
    public func ifNone(
        _ body: () throws -> Void
    ) rethrows -> Optional {
        return try handle(ifSome: noop, ifNone: body)
    }
}

extension Optional {
    /// Returns the wrapped value if present, or throws the given error if the value is absent.
    /// - Parameter error: The error to throw if the value is absent.
    /// - Returns: The unwrapped value.
    @inlinable
    public func unwrapped(throwingIfNil error: Error) throws -> Wrapped {
        return try converge(ifSome: identity, ifNone: try raise(error))
    }

    /// Mandates the presence of the value, aborting execution if the value is absent.
    /// - Parameter message: The string to print upon crashing if the value is absent.
    /// - Parameter file: The file name to print with the message. The default is the file where require(_:file:line:) is called.
    /// - Parameter line: The line number to print along with message. The default is the line number where require(_:file:line:) is called.
    /// - Returns: The unwrapped value.
    @inlinable
    public func require(_ message: String, file: StaticString = #file, line: UInt = #line) -> Wrapped {
        guard let value = self else {
            fatalError(message, file: file, line: line)
        }
        return value
    }
}

/// Transforms a tuple of optionals into an optional tuple.
/// This function returns `nil` if either argument is `nil`.
/// - Parameter optional1: The first optional value to zip.
/// - Parameter optional2: The second optional value to zip.
/// - Returns: A tuple containing both values if present, or `nil` if either value is `nil`.
@inlinable
public func zip<Wrapped1, Wrapped2>(
    _ optional1: Wrapped1?,
    _ optional2: Wrapped2?
) -> (Wrapped1, Wrapped2)? {
    guard
        let optional1 = optional1,
        let optional2 = optional2
    else {
        return nil
    }
    return (optional1, optional2)
}

/// Transforms a tuple of optionals into an optional tuple.
/// This function returns `nil` if any argument is `nil`.
/// - Parameter optional1: The first optional value to zip.
/// - Parameter optional2: The second optional value to zip.
/// - Parameter optional3: The third optional value to zip.
/// - Returns: A tuple containing all values if present, or `nil` if any value is `nil`.
@inlinable
public func zip<Wrapped1, Wrapped2, Wrapped3>(
    _ optional1: Wrapped1?,
    _ optional2: Wrapped2?,
    _ optional3: Wrapped3?
) -> (Wrapped1, Wrapped2, Wrapped3)? {
    guard
        let optional1 = optional1,
        let optional2 = optional2,
        let optional3 = optional3
    else {
        return nil
    }
    return (optional1, optional2, optional3)
}

/// Transforms a tuple of optionals into an optional tuple.
/// This function returns `nil` if any argument is `nil`.
/// - Parameter optional1: The first optional value to zip.
/// - Parameter optional2: The second optional value to zip.
/// - Parameter optional3: The third optional value to zip.
/// - Parameter optional4: The fourth optional value to zip.
/// - Returns: A tuple containing all values if present, or `nil` if any value is `nil`.
@inlinable
public func zip<Wrapped1, Wrapped2, Wrapped3, Wrapped4>(
    _ optional1: Wrapped1?,
    _ optional2: Wrapped2?,
    _ optional3: Wrapped3?,
    _ optional4: Wrapped4?
) -> (Wrapped1, Wrapped2, Wrapped3, Wrapped4)? {
    guard
        let optional1 = optional1,
        let optional2 = optional2,
        let optional3 = optional3,
        let optional4 = optional4
    else {
        return nil
    }
    return (optional1, optional2, optional3, optional4)
}
