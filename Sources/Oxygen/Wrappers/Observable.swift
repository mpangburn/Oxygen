//
//  Observable.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/5/18.
//

import struct Foundation.UUID


/// A token determining the lifetime of an observation.
public final class ObservationToken {
    @usableFromInline
    internal let _invalidate: () -> Void

    @usableFromInline
    internal var _isValid = true

    @usableFromInline
    internal init(_invalidate invalidate: @escaping () -> Void) {
        _invalidate = invalidate
    }

    /// Invalidates the observation corresponding to this token.
    @inlinable
    public func invalidate() {
        guard _isValid else { return }
        _isValid = false
        _invalidate()
    }

    /// Adds the token to the bag for disposal.
    /// The bag manages invalidation of the token by its lifetime.
    /// - Parameter bag: The bag to which to add the token.
    @inlinable
    public func dipose(with bag: DisposeBag) {
        bag.add(self)
    }
}

/// A bag used to manage observation tokens.
/// All tokens contained by the bag are invalidated upon deallocation of the bag.
public final class DisposeBag {
    @usableFromInline
    internal var _tokens: [ObservationToken] = []

    /// Initializes a new dispose bag.
    @inlinable
    public init() { }

    deinit {
        _tokens.forEach { $0.invalidate() }
    }

    /// Adds to the token to the dispose bag.
    /// The token will be invalidated upon deallocation of the bag.
    /// - Parameter token: The token to add.
    @inlinable
    public func add(_ token: ObservationToken) {
        _tokens.append(token)
    }

    /// Adds to the tokens to the dispose bag.
    /// The tokens will be invalidated upon deallocation of the bag.
    /// - Parameter tokens: The tokens to add.
    @inlinable
    public func add<S: Sequence>(contentsOf tokens: S) where S.Element == ObservationToken {
        _tokens += tokens
    }

    /// Adds to the tokens to the dispose bag.
    /// The tokens will be invalidated upon deallocation of the bag.
    /// - Parameter tokens: The tokens to add.
    @inlinable
    public func addTokens(_ tokens: ObservationToken...) {
        add(contentsOf: tokens)
    }
}

/// A class enabling key path-based observation of a wrapped value.
public final class Observable<Value> {
    /// A function responding to a property change.
    /// - Parameter updatedValue: The observed value with the change applied.
    /// - Parameter previousPropertyValue: The previous value of the changed property.
    /// - Parameter newPropertyValue: The new value of the changed property.
    public typealias Observation<PropertyValue> = (
        _ updatedValue: Value,
        _ previousPropertyValue: PropertyValue,
        _ newPropertyValue: PropertyValue
    ) -> Void

    @usableFromInline
    internal var _value: Value

    @usableFromInline
    internal var _observers: [PartialKeyPath<Value>: [UUID: Observation<Any>]] = [:]

    /// Creates a new `Observable` instance managing the value.
    /// - Parameter value: The value for which to begin observation management.
    @inlinable
    public init(_ value: Value) {
        _value = value
    }

    /// Returns the value of the property specified by the key path.
    ///
    /// Setting a new value through this subscript notifies observers of the property.
    ///
    /// - Parameter keyPath: The key path to the value to retrieve.
    /// - Returns: The value of the property specified by the key path.
    @inlinable
    public subscript<PropertyValue>(keyPath: WritableKeyPath<Value, PropertyValue>) -> PropertyValue {
        get {
            return _value[keyPath: keyPath]
        }
        set(newPropertyValue) {
            let previousPropertyValue = _value[keyPath: keyPath]
            _value[keyPath: keyPath] = newPropertyValue
            _observers[keyPath]?.values.forEach { observe in
                observe(_value, previousPropertyValue, newPropertyValue)
            }
        }
    }

    @usableFromInline
    internal func _addObserver<PropertyValue>(
        for keyPath: WritableKeyPath<Value, PropertyValue>,
        sendingCurrentValue sendCurrentValue: Bool,
        observation observe: @escaping Observation<PropertyValue>
    ) -> ObservationToken {
        let id = UUID()
        _observers[keyPath, default: [:]][id] = { value, oldPropertyValue, newPropertyValue in
            observe(value, oldPropertyValue as! PropertyValue, newPropertyValue as! PropertyValue)
        }
        if sendCurrentValue {
            let PropertyValue = _value[keyPath: keyPath]
            observe(_value, PropertyValue, PropertyValue)
        }
        return ObservationToken { [weak self] in
            self?._observers[keyPath]?.removeValue(forKey: id)
        }
    }

    /// Observes changes to the property specified by the key path.
    ///
    /// The observation is invoked immediately with the current value.
    /// On this first invocation, the old and new property values passed
    /// to the observation closure will be the same.
    /// - Parameter keyPath: The key path to the property to observe.
    /// - Parameter observation: A closure responding to changes to the observed property.
    /// - Returns: An observation token determining the lifetime of the observation.
    @inlinable
    public func observe<PropertyValue>(
        _ keyPath: WritableKeyPath<Value, PropertyValue>,
        with observation: @escaping Observation<PropertyValue>
    ) -> ObservationToken {
        return _addObserver(for: keyPath, sendingCurrentValue: true, observation: observation)
    }

    /// Observes changes to the property specified by the key path.
    ///
    /// The observer will be invoked for the first time when the property next changes.
    /// - Parameter keyPath: The key path to the property to observe.
    /// - Parameter observation: A closure responding to changes to the observed property.
    /// - Returns: An observation token determining the lifetime of the observation.
    @inlinable
    public func observeNext<PropertyValue>(
        _ keyPath: WritableKeyPath<Value, PropertyValue>,
        with observation: @escaping Observation<PropertyValue>
    ) -> ObservationToken {
        return _addObserver(for: keyPath, sendingCurrentValue: false, observation: observation)
    }
}
