//
//  Atomic.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/31/18.
//

import class Dispatch.DispatchQueue


/// A value whose reads and writes are synchronous.
/// Useful in working with concurrency.
public final class Atomic<Value> {
    @usableFromInline
    internal var _value: Value

    @usableFromInline
    internal let _accessQueue = DispatchQueue(label: "com.mpangburn.oxygen.atomic")

    /// Creates a new atomic value, ensuring synchronous reads and writes.
    /// - Parameter value: The value to wrap.
    @inlinable
    public init(_ value: Value) {
        self._value = value
    }

    /// The wrapped value accessed synchronously on a serial queue.
    ///
    /// This property is read-only.
    /// Use `modify(with:)`, `update(with:)`, or `assign(to:)` to change its value.
    @inlinable
    public var value: Value {
        return _accessQueue.sync { _value }
    }

    /// Synchronously mutates the the wrapped value.
    /// - Parameter mutate: The function used to mutate the value.
    /// - Returns: The modified value.
    @inlinable
    @discardableResult
    public func modify(with mutate: (inout Value) -> Void) -> Value {
        return _accessQueue.sync { mutate(&self._value); return _value }
    }

    /// Synchronously updates the wrapped value using a transformation.
    /// - Parameter transform: The transformation used to update the value.
    /// - Returns: The updated value.
    @inlinable
    @discardableResult
    public func update(with transform: (Value) -> Value) -> Value {
        return modify { $0 = transform($0) }
    }

    /// Synchronously assigns the wrapped value to the new value.
    /// - Parameter value: The value to assign.
    @inlinable
    public func assign(to value: Value) {
        modify { $0 = value }
    }
}

extension Atomic {
    /// Returns a new atomic value by applying the transformation to the wrapped value.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new atomic value produced by applying the transformation to the wrapped value.
    @inlinable
    public func map<NewValue>(
        _ transform: (Value) throws -> NewValue
    ) rethrows -> Atomic<NewValue> {
        return .init(try transform(value))
    }

    /// Returns a new atomic value by applying the transformation to the wrapped value.
    /// - Parameter transform: The transformation to apply.
    /// - Returns: A new atomic value produced by applying the transformation to the wrapped value.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Atomic<NewValue>
    ) rethrows -> Atomic<NewValue> {
        return try transform(value)
    }
}

/// Transforms a tuple of atomic values into an atomic tuple.
/// - Parameter atomic1: The first atomic value to zip.
/// - Parameter atomic2: The second atomic value to zip.
/// - Returns: An atomic tuple.
@inlinable
public func zip<Value1, Value2>(
    _ atomic1: Atomic<Value1>,
    _ atomic2: Atomic<Value2>
) -> Atomic<(Value1, Value2)> {
    return Atomic((atomic1.value, atomic2.value))
}
