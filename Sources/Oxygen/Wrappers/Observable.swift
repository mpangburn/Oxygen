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
    public typealias Observation<Subvalue> = (
        _ updatedValue: Value,
        _ previousPropertyValue: Subvalue,
        _ newPropertyValue: Subvalue
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
    public subscript<Subvalue>(keyPath: WritableKeyPath<Value, Subvalue>) -> Subvalue {
        get {
            return _value[keyPath: keyPath]
        }
        set(newSubvalue) {
            let previousSubvalue = _value[keyPath: keyPath]
            _value[keyPath: keyPath] = newSubvalue
            _observers[keyPath]?.values.forEach { observe in
                observe(_value, previousSubvalue, newSubvalue)
            }
        }
    }

    @usableFromInline
    internal func _addObserver<Subvalue>(
        for keyPath: WritableKeyPath<Value, Subvalue>,
        sendingCurrentValue sendCurrentValue: Bool,
        observation: @escaping Observation<Subvalue>
    ) -> ObservationToken {
        let id = UUID()
        _observers[keyPath, default: [:]][id] = { value, oldSubvalue, newSubvalue in
            observation(value, oldSubvalue as! Subvalue, newSubvalue as! Subvalue)
        }
        if sendCurrentValue {
            let subvalue = _value[keyPath: keyPath]
            observation(_value, subvalue, subvalue)
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
    public func observe<Subvalue>(
        _ keyPath: WritableKeyPath<Value, Subvalue>,
        with observation: @escaping Observation<Subvalue>
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
    public func observeNext<Subvalue>(
        _ keyPath: WritableKeyPath<Value, Subvalue>,
        with observation: @escaping Observation<Subvalue>
    ) -> ObservationToken {
        return _addObserver(for: keyPath, sendingCurrentValue: false, observation: observation)
    }
}
