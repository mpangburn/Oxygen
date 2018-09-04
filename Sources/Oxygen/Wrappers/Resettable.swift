//
//  Resettable.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Wraps a value, providing a default fallback to which the value can be reset.
public struct Resettable<Value> {
    @usableFromInline
    internal let _fallback: () -> Value

    @usableFromInline
    internal var _value: Value?

    /// The wrapped value.
    ///
    /// If the value has not been set, accessing this property returns
    /// the result of invoking the fallback function.
    @inlinable
    public var value: Value {
        get {
            return _value ?? _fallback()
        }
        set {
            _value = newValue
        }
    }

    /// Creates a new resettable value with the given fallback.
    /// - Parameter fallback: A producing the fallback value. The result of this computation is never cached.
    @inlinable
    public init(fallback: @escaping () -> Value) {
        self._fallback = fallback
    }

    /// Creates a new resettable value with the given fallback.
    /// - Parameter fallback: An autoclosure producing the fallback value. The result of this computation is never cached.
    @inlinable
    public init(_ fallback: @autoclosure @escaping () -> Value) {
        self._fallback = fallback
    }

    /// Resets the value to its original state.
    @inlinable
    public mutating func reset() {
        _value = nil
    }
}

extension Resettable {
    /// Returns a new resettable value by applying the transformation to the wrapped value and its fallback.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new resettable value applying the transformation to the wrapped value and its fallback.
    @inlinable
    public func map<NewValue>(
        _ transform: @escaping (Value) -> NewValue
    ) -> Resettable<NewValue> {
        var result = Resettable<NewValue> { [_fallback] in transform(_fallback()) }
        result._value = _value.map(transform)
        return result
    }

    /// Returns a new resettable value by applying the transformation to the wrapped value.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new resettable value produced by applying the transformation to the wrapped value.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Resettable<NewValue>
    ) rethrows -> Resettable<NewValue> {
        return try transform(value)
    }
}

/// Transforms a tuple of resettable values into a resettable tuple.
/// - Parameter resettable1: The first resettable value to zip.
/// - Parameter resettable2: The second resettable value to zip.
/// - Returns: A resettable tuple containing the values of the arguments.
@inlinable
public func zip<Value1, Value2>(
    _ resettable1: Resettable<Value1>,
    _ resettable2: Resettable<Value2>
) -> Resettable<(Value1, Value2)> {
    var result = Resettable((resettable1._fallback(), resettable2._fallback()))
    result.value = (resettable1.value, resettable2.value)
    return result
}

// MARK: - Conditional Conformances

extension Resettable: Container { }
extension Resettable: Equatable where Value: Equatable { }
extension Resettable: Hashable where Value: Hashable { }
