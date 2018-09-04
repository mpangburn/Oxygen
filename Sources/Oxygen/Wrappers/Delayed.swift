//
//  Delayed.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Represents a variable to be initialized at a later point in time.
public struct Delayed<Value> {
    @usableFromInline
    internal var _value: Value?

    /// The value of the variable.
    ///
    /// Accessing this value prior to assignment is a programmer error
    /// and will result in a runtime crash.
    @inlinable
    public var value: Value {
        get {
            guard let value = _value else {
                fatalError("Delayed variable used before being initialized.")
            }
            return value
        }
        set {
            _value = newValue
        }
    }

    /// Creates a new variable to be initialized at a later point in time.
    @inlinable
    public init() { }
}

extension Delayed {
    /// Returns a new value wrapping the result of the transformation applied to the wrapped value.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new wrapped value produced by applying the transformation to the wrapped value.
    @inlinable
    public func map<NewValue>(
        _ transform: (Value) throws -> NewValue
    ) rethrows -> Delayed<NewValue> {
        var result = Delayed<NewValue>()
        result.value = try transform(value)
        return result
    }

    /// Returns a new wrapped value produced by applying the transformation to the wrapped value.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new wrapped value produced by applying the transformation to the wrapped value.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Delayed<NewValue>
    ) rethrows -> Delayed<NewValue> {
        return try transform(value)
    }
}

// MARK: - Conditional Conformances

// No need to conform to `Container` here;
// The value is the only stored property, so the compiler can synthesize these implementations.
extension Delayed: Equatable where Value: Equatable { }
extension Delayed: Hashable where Value: Hashable { }
extension Delayed: Encodable where Value: Encodable { }
extension Delayed: Decodable where Value: Decodable { }
