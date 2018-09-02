//
//  Result.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Represents the result of an operation.
/// Contains the result of the operation in the case of success or an explanatory error in the case of failure.
public enum Result<Value, Error> {
    /// Represents the successful completion of an operation. The associated value contains the operation output.
    case success(Value)

    /// Represents the failed completion of an operation. The associated value contains an explanatory error.
    case failure(Error)
}

extension Result {
    /// Collapses the result into a single value.
    /// - Parameter valueTransform: The transformation to apply to the value in the case of success.
    /// - Parameter errorTransform: The transformation to apply to the error in the case of failure.
    /// - Returns: The transformed value in the case of success, or the transformed error in the case of failure.
    @inlinable
    public func converge<T>(
        ifSuccess valueTransform: (Value) throws -> T,
        ifFailure errorTransform: (Error) throws -> T
    ) rethrows -> T {
        switch self {
        case .success(let value):
            return try valueTransform(value)
        case .failure(let error):
            return try errorTransform(error)
        }
    }

    /// The value in the case of success, or `nil` in the case of failure.
    @inlinable
    public var value: Value? {
        return converge(ifSuccess: Optional.some, ifFailure: constant(nil))
    }

    /// The error in the case of failure, or `nil` in the case of success.
    @inlinable
    public var error: Error? {
        return converge(ifSuccess: constant(nil), ifFailure: Optional.some)
    }

    /// Returns `true` in the case of success and `false` in the case of failure.
    @inlinable
    public var isSuccess: Bool {
        return error == nil
    }

    /// Returns `true` in the case of failure and `false` in the case of success.
    @inlinable
    public var isFailure: Bool {
        return error != nil
    }
}

extension Result {
    /// Returns the result with the appropriate transformation applied to the value or error.
    /// - Parameter valueTransform: The transformation to apply to the value in the case of success.
    /// - Parameter errorTransform: The transformation to apply to the error in the case of failure.
    /// - Returns: The transformed result.
    @inlinable
    public func bimap<NewValue, NewError>(
        ifSuccess valueTransform: (Value) throws -> NewValue,
        ifFailure errorTransform: (Error) throws -> NewError
    ) rethrows -> Result<NewValue, NewError> {
        return try converge(
            ifSuccess: { .success(try valueTransform($0)) },
            ifFailure: { .failure(try errorTransform($0)) }
        )
    }

    /// Returns the result with the transformation applied to the value in the case of success,
    /// or the rewrapped error in the case of failure.
    /// - Parameter transform: The transformation to apply to the value in the case of success.
    /// - Returns: The transformed result.
    @inlinable
    public func map<NewValue>(
        _ transform: (Value) throws -> NewValue
    ) rethrows -> Result<NewValue, Error> {
        return try bimap(ifSuccess: transform, ifFailure: identity)
    }

    /// Returns the result with the transformation applied to the error in the case of error,
    /// or the rewrapped value in the case of success.
    /// - Parameter transform: The transformation to apply to the error in the case of failure.
    /// - Returns: The transformed result.
    @inlinable
    public func mapError<NewError>(
        _ transform: (Error) throws -> NewError
    ) rethrows -> Result<Value, NewError> {
        return try bimap(ifSuccess: identity, ifFailure: transform)
    }

    /// Returns the transformation applied to the value in the case of success,
    /// or the rewrapped error in the case of failure.
    /// - Parameter transform: The transformation to apply to the value in the case of success.
    /// - Returns: The transformed result.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Result<NewValue, Error>
    ) rethrows -> Result<NewValue, Error> {
        return try converge(ifSuccess: transform, ifFailure: Result<NewValue, Error>.failure)
    }

    /// Returns the transformation applied to the error in the case of failure,
    /// or the rewrapped value in the case of success.
    /// - Parameter transform: The transformation to apply to the error in the case of failure.
    /// - Returns: The transformed result.
    @inlinable
    public func flatMapError<NewError>(
        _ transform: (Error) throws -> Result<Value, NewError>
    ) rethrows -> Result<Value, NewError> {
        return try converge(ifSuccess: Result<Value, NewError>.success, ifFailure: transform)
    }
}

extension Result {
    /// Performs a side effect depending on the contained value.
    /// - Parameter successHandler: The function to invoke in the case of success.
    /// - Parameter errorHandler: The function to invoke in the case of failure.
    /// - Returns: The result instance.
    @inlinable
    @discardableResult
    public func handle(
        ifSuccess successHandler: (Value) throws -> Void,
        ifFailure errorHandler: (Error) throws -> Void
    ) rethrows -> Result {
        try converge(ifSuccess: successHandler, ifFailure: errorHandler)
        return self
    }

    /// Performs a side effect in the case of success.
    /// - Parameter handler: The function to invoke in the case of success.
    /// - Returns: The result instance.
    @inlinable
    @discardableResult
    public func ifSuccess(_ handler: (Value) -> Void) -> Result {
        return handle(ifSuccess: handler, ifFailure: noop)
    }

    /// Performs a side effect in the case of failure.
    /// - Parameter handler: The function to invoke in the case of failure.
    /// - Returns: The result instance.
    @inlinable
    @discardableResult
    public func ifFailure(_ handler: (Error) -> Void) -> Result {
        return handle(ifSuccess: noop, ifFailure: handler)
    }
}

extension Result {
    /// Returns the value in the case of success, or the supplied alternative in the case of failure.
    /// - Parameter alternative: An autoclosure producing the value to return in the case of failure.
    /// - Returns: The value in the case of success, or the supplied alternative in the case of failure.
    @inlinable
    public func recoveringValue(
        with alternative: @autoclosure () throws -> Value
    ) rethrows -> Value {
        return try value ?? alternative()
    }

    /// Returns this instance in the case of success, or the supplied alternative in the case of failure.
    /// - Parameter alternative: An autoclosure producing the result to return in the case of failure.
    /// - Returns: This instance in the case of success, or the supplied alternative in the case of failure.
    @inlinable
    public func recovering(
        with alternative: @autoclosure () throws -> Result
    ) rethrows -> Result {
        return isSuccess ? self : try alternative()
    }
}

extension Result where Error: Swift.Error {
    /// Returns the value in the case of success or throws the error in the case of failure.
    @inlinable
    public func unwrap() throws -> Value {
        return try converge(ifSuccess: identity, ifFailure: raise)
    }
}

extension Result where Error == Swift.Error {
    /// Creates a `Result` from the given throwing function.
    /// - Parameter throwingOperation: A throwing closure from which to create the `Result`.
    /// - Returns: A instance of success containing the output of the operation,
    ///            or an instance of failure containing the caught error.
    @inlinable
    public init(attempting throwingOperation: () throws -> Value) {
        self = attempt(.success(try throwingOperation()), ifError: Result.failure)
    }

    /// Creates a `Result` from the given throwing function.
    /// - Parameter throwingOperation: A throwing autoclosure from which to create the `Result`.
    /// - Returns: A instance of success containing the output of the operation,
    ///            or an instance of failure containing the caught error.
    @inlinable
    public init(_ throwingOperation: @autoclosure () throws -> Value) {
        self.init(attempting: throwingOperation)
    }

    /// Returns the value in the case of success or throws the error in the case of failure.
    @inlinable
    public func unwrap() throws -> Value {
        return try converge(ifSuccess: identity, ifFailure: raise)
    }

    /// Applies the transformation to the value in the case of success, rewrapping the error if thrown.
    /// - Parameter transform: The throwing transformation to apply to the value in the case of success.
    /// - Returns: The transformed result.
    @inlinable
    public func tryMap<NewValue>(
        _ transform: @escaping (Value) throws -> NewValue
    ) -> Result<NewValue, Error> {
        return attempt(try map(transform), ifError: Result<NewValue, Error>.failure)
    }
}

/// Returns a `Result` containing one of:
/// - A tuple of both success values.
/// - The error if exactly one of the results is a failure.
/// - The error chosen by the given handler if both results are failures.
/// - Parameter result1: The first result to zip.
/// - Parameter result2: The second result to zip.
/// - Parameter errorSelector: The handler invoked in the case of two failures
///                            to choose between the two errors.
/// - Returns: An instance combining the two results.
@inlinable
public func zip<Value1, Value2, Error>(
    _ result1: Result<Value1, Error>,
    _ result2: Result<Value2, Error>,
    selectingErrorWith errorSelector: (Error, Error) throws -> Error
) rethrows -> Result<(Value1, Value2), Error> {
    switch (result1, result2) {
    case (.success(let value1), .success(let value2)):
        return .success((value1, value2))
    case (.success(_), .failure(let error)):
        return .failure(error)
    case (.failure(let error), .success(_)):
        return .failure(error)
    case (.failure(let error1), .failure(let error2)):
        return .failure(try errorSelector(error1, error2))
    }
}

/// Returns a `Result` containing one of:
/// - A tuple of both success values.
/// - The error if exactly one of the results is a failure.
/// - The error of the first result if both results are failures.
/// - Parameter result1: The first result to zip.
/// - Parameter result2: The second result to zip.
/// - Returns: An instance combining the two results.
@inlinable
public func zip<Value1, Value2, Error>(
    _ result1: Result<Value1, Error>,
    _ result2: Result<Value2, Error>
) -> Result<(Value1, Value2), Error> {
    return zip(result1, result2, selectingErrorWith: { first, _ in first })
}
