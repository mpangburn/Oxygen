//
//  Lazy.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

// A lazily computed value.
///
/// The computation with which the instance is initialized is performed
/// only when its `value` property is first accessed.
/// After performing the computation, the result is cached for future accesses.
public struct Lazy<Value> {
    @usableFromInline
    internal let _computation: () -> Value

    @usableFromInline
    internal var _value: Value?

    /// The lazily computed value.
    ///
    /// When accessed for the first time, the computation is performed.
    /// The result of the computation is then cached for future accesses.
    @inlinable
    public var value: Value {
        mutating get {
            if let value = _value {
                return value
            } else {
                let value = _computation()
                _value = value
                return value
            }
        }
        set {
            _value = newValue
        }
    }

    /// Creates a lazy cache for the value provided by the given computation.
    /// - Parameter computation: A closure computing the value.
    @inlinable
    public init(_ computation: @escaping () -> Value) {
        _computation = computation
    }

    /// Clears the result of the computation to reclaim memory space.
    @inlinable
    public mutating func clear() {
        _value = nil
    }
}

extension Lazy {
    /// Returns an instance lazily applying the given transformation to the computed value.
    /// - Parameter transform: The transformation to lazily apply to the computed value.
    /// - Returns: An instance lazily applying the transformation to the computed value.
    @inlinable
    public func map<NewValue>(
        _ transform: @escaping (Value) -> NewValue
    ) -> Lazy<NewValue> {
        if let value = _value {
            return .init { transform(value) }
        } else {
            return .init { [_computation] in transform(_computation()) }
        }
    }

    /// Returns an instance lazily applying the given transformation to the computed value and flattening the result.
    /// - Parameter transform: The transformation to lazily apply to the computed value.
    /// - Returns: An instance lazily applying the transformation to the computed value and flattening the result.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: @escaping (Value) -> Lazy<NewValue>
    ) -> Lazy<NewValue> {
        var result = map(transform)
        return result.value
    }
}

/// Returns an instance lazily computing a tuple of the computed values of the arguments.
/// - Parameter lazy1: The first lazily computed value to zip.
/// - Parameter lazy2: The second lazily computed value to zip.
/// - Returns: An instance lazily computing a tuple of the computed values of the arguments.
@inlinable
public func zip<Value1, Value2>(
    _ lazy1: Lazy<Value1>,
    _ lazy2: Lazy<Value2>
) -> Lazy<(Value1, Value2)> {
    var (lazy1, lazy2) = (lazy1, lazy2)
    return Lazy { (lazy1.value, lazy2.value) }
}
