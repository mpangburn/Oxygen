//
//  Weak.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Holds a weak reference to its underlying value.
///
/// `Weak` is useful for avoiding retain cycles where the typical `weak`
/// attribute cannot be applied, such as on values contained by a collection.
public struct Weak<Value> {
    // Rather than constrain `Value` to `AnyObject`, we store the value privately as `AnyObject`.
    // This allows us to hold weak references to class-constrained protocol types,
    // which as types do not themselves conform to `AnyObject`.
    @usableFromInline
    internal weak var _value: AnyObject?

    /// The wrapped value to which a reference is weakly held.
    @inlinable
    public var value: Value? {
        get {
            return _value as? Value
        }
        set {
            // Allow the initializer to handle the optional logic.
            self = Weak(newValue)
        }
    }

    /// Creates a box holding a weak reference to the value.
    /// - Parameter value: The value to box.
    @inlinable
    public init(_ value: Value) {
        _value = value as AnyObject
    }

    /// Creates a box holding a weak reference to the value.
    /// - Parameter value: The value to box.
    @inlinable
    public init(_ value: Value?) {
        // Unwrap prior to casting to avoid a nested optional in _value.
        if let value = value {
            _value = value as AnyObject
        } else {
            _value = nil
        }
    }
}

extension Weak {
    /// Returns a weak reference with the given transformation applied to the underlying value.
    /// - Parameter transform: The transformation to apply to the underlying value.
    /// - Returns: A weak reference with the transformation applied.
    @inlinable
    public func map<NewValue>(
        _ transform: (Value) throws -> (NewValue)
    ) rethrows -> Weak<NewValue> {
        return .init(try value.map(transform))
    }

    /// Returns a weak reference with the given transformation applied to the underlying value and flattened.
    /// - Parameter transform: The transformation to apply to the underlying value.
    /// - Returns: A weak reference with the transformation applied and flattened.
    @inlinable
    public func flatMap<NewValue>(
        _ transform: (Value) throws -> Weak<NewValue>
    ) rethrows -> Weak<NewValue> {
        return try value.converge(ifSome: transform, ifNone: .init(nil))
    }
}

// MARK: Conditional Conformances

extension Weak: CreatableContainer { }
extension Weak: Equatable where Value: Equatable { }
extension Weak: Hashable where Value: Hashable { }
extension Weak: Encodable where Value: Encodable { }
extension Weak: Decodable where Value: Decodable { }
