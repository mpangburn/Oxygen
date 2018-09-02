//
//  Reference.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Wraps an underlying value to provide reference semantics.
public final class Reference<Value> {
    /// The wrapped value.
    public var value: Value

    /// Creates a new reference wrapper with the value.
    /// - Parameter value: The value to wrap.
    @inlinable
    public init(_ value: Value) {
        self.value = value
    }

    /// Returns a new reference to the wrapped value.
    @inlinable
    public func copy() -> Reference {
        return Reference(value)
    }
}

extension Reference {
    /// Returns a new reference wrapping the result of the transformation applied to the wrapped value.
    /// - Parameter transform: The transformation to apply to the wrapped value.
    /// - Returns: A new reference wrapping the transformed value.
    @inlinable
    public func map<NewValue>(
        _ transform: (Value) throws -> NewValue
    ) rethrows -> Reference<NewValue> {
        return .init(try transform(value))
    }

    /// Returns a new reference produced by applying the transformation to the wrapped value.
    /// - Parameter transform: The transformation to apply to the wrapped value.
    /// - Returns: A new reference produced by applying the transformation to the wrapped value.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Reference<NewValue>
    ) rethrows -> Reference<NewValue> {
        return try transform(value)
    }
}

/// Transforms a tuple of references into a reference to a tuple.
/// - Parameter reference1: The first reference to zip.
/// - Parameter reference2: The second reference to zip.
/// - Returns: A reference to a tuple containing the values of the arguments.
@inlinable
public func zip<Value1, Value2>(
    _ reference1: Reference<Value1>,
    _ reference2: Reference<Value2>
) -> Reference<(Value1, Value2)> {
    return Reference((reference1.value, reference2.value))
}

// MARK: - Conditional Conformances

extension Reference: CreatableContainer { }
extension Reference: Equatable where Value: Equatable { }
extension Reference: Hashable where Value: Hashable { }
extension Reference: Encodable where Value: Encodable { }
extension Reference: Decodable where Value: Decodable { }
