//
//  KeyPath.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// Returns a getter function for the given key path. Useful in composing property access with functions.
/// - Parameter keyPath: The key path to use in producing the getter function.
/// - Returns: A getter function correpsonding to the key path.
@inlinable
public func get<Root, Value>(
    _ keyPath: KeyPath<Root, Value>
) -> (Root) -> Value {
    return { root in
        root[keyPath: keyPath]
    }
}

/// Returns a combining function lifted using a transformation.
///
/// Useful for calls to `Sequence.sorted(by:)` and `Sequence.map(_:)` over tuples.
/// - Parameter extractValue: A function transforming an input value to an intermediate value.
/// - Parameter combine: A function combining two intermediate values into an output value.
/// - Returns: A function lifting `combine` via `extractValue`.
@inlinable
public func their<Input, Intermediate, Output>(
    _ extractIntermediate: @escaping (Input) -> Intermediate,
    _ combine: @escaping (Intermediate, Intermediate) -> Output
) -> (Input, Input) -> Output {
    return { input1, input2 in
        combine(extractIntermediate(input1), extractIntermediate(input2))
    }
}

/// Returns a combining function lifted using a key path.
///
/// Useful for calls to `Sequence.sorted(by:)` and `Sequence.map(_:)` over tuples.
/// - Parameter intermediateKeyPath: A key path from an input value to an intermediate value.
/// - Parameter combine: A function combining two intermediate values into an output value.
/// - Returns: A function lifting `combine` via `intermediateKeyPath`.
@inlinable
public func their<Input, Intermediate, Output>(
    _ intermediateKeyPath: KeyPath<Input, Intermediate>,
    _ combine: @escaping (Intermediate, Intermediate) -> Output
) -> (Input, Input) -> Output {
    return their(get(intermediateKeyPath), combine)
}

/// Returns a function that combines its first argument with the result of the
/// transformation applied to its second argument.
///
/// Useful for calls to `Sequence.reduce(_:_:)`.
/// - Parameter extractValue: A function transforming an input value to the output value to combine.
/// - Parameter combineValues: A function combining two output values.
/// - Returns: A function that combines its first argument with the result of the
///            transformation applied to its second argument.
@inlinable
public func combining<Input, Output>(
    _ extractValue: @escaping (Input) -> Output,
    with combineValues: @escaping (Output, Output) -> Output
) -> (Output, Input) -> Output {
    return { value, root in
        combineValues(value, extractValue(root))
    }
}

/// Returns a function that combines its first argument with the result of the
/// transformation applied to its second argument.
///
/// Useful for calls to `Sequence.reduce(_:_:)`.
/// - Parameter keyPath: A key path from an input value to the output value to combine.
/// - Parameter combineValues: A function combining two output values.
/// - Returns: A function that combines its first argument with the key path value of its second argument.
@inlinable
public func combining<Input, Output>(
    _ keyPath: KeyPath<Input, Output>,
    with combineValues: @escaping (Output, Output) -> Output
) -> (Output, Input) -> Output {
    return combining(get(keyPath), with: combineValues)
}

/// Returns a function that combines its first argument with the result of the
/// transformation applied to its second argument.
///
/// Useful for calls to `Sequence.reduce(into:_:)`.
/// - Parameter extractValue: A function transforming an input value to the output value to combine.
/// - Parameter combineValues: A function combining two output values.
/// - Returns: A function that combines its first argument with the result of the
///            transformation applied to its second argument.
@inlinable
public func combine<Input, Output>(
    _ extractValue: @escaping (Input) -> Output,
    with combineValues: @escaping (inout Output, Output) -> Void
) -> (inout Output, Input) -> Void {
    return { value, root in
        combineValues(&value, extractValue(root))
    }
}

/// Returns a function that combines its first argument with the result of the
/// transformation applied to its second argument.
///
/// Useful for calls to `Sequence.reduce(into:_:)`.
/// - Parameter keyPath: A key path from an input value to the output value to combine.
/// - Parameter combineValues: A function combining two output values.
/// - Returns: A function that combines its first argument with the key path value of its second argument.
@inlinable
public func combine<Input, Output>(
    _ keyPath: KeyPath<Input, Output>,
    with combineValues: @escaping (inout Output, Output) -> Void
) -> (inout Output, Input) -> Void {
    return combine(get(keyPath), with: combineValues)
}

/// Returns a function that mutates a root value by applying the update to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter updateValue: A closure that takes in the previous value and returns the updated value.
/// - Returns: A function that mutates a root value by applying the update to the value at the key path.
@inlinable
public func update<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    with updateValue: @escaping (Value) -> Value
) -> (inout Root) -> Void {
    return { root in
        root[keyPath: keyPath] = updateValue(root[keyPath: keyPath])
    }
}

/// Returns a function that mutates a root value by applying the update to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter mutateValue: A closure that mutates the existing value.
/// - Returns: A function that mutates a root value by applying the update to the value at the key path.
@inlinable
public func update<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    with mutateValue: @escaping (inout Value) -> Void
) -> (inout Root) -> Void {
    return { root in
        mutateValue(&root[keyPath: keyPath])
    }
}

/// Returns a function that mutates a root value reference by applying the update to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter updateValue: A closure that takes in the previous value and returns the updated value.
/// - Returns: A function that mutates a root value reference by applying the update to the value at the key path.
@inlinable
public func update<Root, Value>(
    _ keyPath: ReferenceWritableKeyPath<Root, Value>,
    with updateValue: @escaping (Value) -> Value
) -> (Root) -> Void {
    return { root in
        root[keyPath: keyPath] = updateValue(root[keyPath: keyPath])
    }
}

/// Returns a function that mutates a root value reference by applying the update to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter mutateValue: A closure that mutates the existing value.
/// - Returns: A function that mutates a root value reference by applying the update to the value at the key path.
@inlinable
public func update<Root, Value>(
    _ keyPath: ReferenceWritableKeyPath<Root, Value>,
    with mutateValue: @escaping (inout Value) -> Void
) -> (Root) -> Void {
    return { root in
        mutateValue(&root[keyPath: keyPath])
    }
}

/// Returns a function that mutates a root value by reassigning the value at the key path.
/// - Parameter keyPath: The key path for the property to set.
/// - Parameter value: The value to assign to the property at the key path.
/// - Returns: A function that mutates a root value by reassigning the value at the key path.
@inlinable
public func set<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    to value: Value
) -> (inout Root) -> Void {
    return { root in
        root[keyPath: keyPath] = value
    }
}

/// Returns a function that mutates a root value reference by reassigning the value at the key path.
/// - Parameter keyPath: The key path for the property to set.
/// - Parameter value: The value to assign to the property at the key path.
/// - Returns: A function that mutates a root value reference by reassigning the value at the key path.
@inlinable
public func set<Root, Value>(
    _ keyPath: ReferenceWritableKeyPath<Root, Value>,
    to value: Value
) -> (Root) -> Void {
    return { root in
        root[keyPath: keyPath] = value
    }
}

/// Returns a function that returns the root value with the update applied to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter updateValue: A closure that takes in the previous value and returns the updated value.
/// - Returns: A function that returns the root value with the update applied to the value at the key path.
/// - Note: This function relies on copy-on-write value semantics for the root type.
///         Using this function for values with reference semantics may produce unexpected results.
@inlinable
public func updating<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    with updateValue: @escaping (Value) -> Value
) -> (Root) -> Root {
    return { root in
        with(root, update(keyPath, with: updateValue))
    }
}

/// Returns a function that returns the root value with the update applied to the value at the key path.
/// - Parameter keyPath: The key path for the property to update.
/// - Parameter mutateValue: A closure that mutates the existing value.
/// - Returns: A function that returns the root value with the update applied to the value at the key path.
/// - Note: This function relies on copy-on-write value semantics for the root type.
///         Using this function for values with reference semantics may produce unexpected results.
@inlinable
public func updating<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    with mutateValue: @escaping (inout Value) -> Void
) -> (Root) -> Root {
    return { root in
        with(root, update(keyPath, with: mutateValue))
    }
}

/// Returns a function that returns the root value with value at the key path reassigned.
/// - Parameter keyPath: The key path for the property to set.
/// - Parameter value: The value to assign to the property at the key path.
/// - Returns: A function that returns the root value with value at the key path reassigned.
/// - Note: This function relies on copy-on-write value semantics for the root type.
///         Using this function for values with reference semantics may produce unexpected results.
@inlinable
public func setting<Root, Value>(
    _ keyPath: WritableKeyPath<Root, Value>,
    to value: Value
) -> (Root) -> Root {
    return { root in
        with(root, set(keyPath, to: value))
    }
}
