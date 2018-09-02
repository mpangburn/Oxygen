//
//  Functions.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// The identity function.
/// - Parameter value: The value to return.
/// - Returns: The given value, unmodified.
@inlinable
public func identity<Value>(_ value: Value) -> Value {
    return value
}

/// Returns a constant function—a function that ignores its input in producing its output.
/// - Parameter output: The value to return in the resulting function.
/// - Returns: A constant function returning the given output value.
@inlinable
public func constant<Input, Output>(
    _ output: Output
) -> (Input) -> Output {
    return { _ in output }
}

/// A function that does nothing.
/// - Parameter input: An ignored input value.
@inlinable
public func noop<Input>(_ input: Input) -> Void { }

/// A polymorphic function that throws the given error.
/// - Parameter error: The error to throw.
/// - Returns: This function will always throw; it will never produce output.
@inlinable
public func raise<Output>(_ error: Error) throws -> Output {
    throw error
}

/// Returns a function that unconditionally throws the given error.
/// - Parameter error: The error to throw in the returned function.
/// - Returns: A function that unconditionally throws the given error.
@inlinable
public func raise<Input, Output>(
    _ error: Error
) -> (Input) throws -> Output {
    return { _ in throw error }
}

/// Invokes the given function.
/// - Parameter provider: A function that takes no arguments and returns a value.
/// - Returns: The output of the given the function.
@inlinable
public func invoke<Output>(
    _ provider: () throws -> Output
) rethrows -> Output {
    return try provider()
}

/// Returns a function that intercepts the input by performing a side effect.
/// Useful in composing side effects with pure functions.
/// - Parameter sideEffect: A side effect to perform on the input value.
/// - Returns: A function that performs a side effect on then returns its input.
@inlinable
public func intercept<Input>(
    with sideEffect: @escaping (Input) -> Void
) -> (Input) -> (Input) {
    return { input in
        sideEffect(input)
        return input
    }
}

/// Transforms a function of type `(Input) -> Input`
/// into an in-place mutation of type `(inout Input) -> Void`.
/// - Parameter transform: A type-preserving transformation function.
/// - Returns: An `inout` version of the given transformation function.
@inlinable
public func mutatingVariant<Input>(
    of transform: @escaping (Input) -> Input
) -> (inout Input) -> Void {
    return { input in
        input = transform(input)
    }
}

/// Transforms a function of type `(inout Input) -> Void`
/// into a type-preserving transformation of type `(Input) -> Input`.
/// - Parameter mutate: An in-place mutation.
/// - Returns: A function that creates a copy of its input, performs the mutation on the copy, and returns the result.
/// - Note: This function relies on copy-on-write value semantics. Using reference types may produce unexpected results.
@inlinable
public func nonmutatingVariant<Input>(
    of mutate: @escaping (inout Input) -> Void
) -> (Input) -> Input {
    return { input in
        var input = input
        mutate(&input)
        return input
    }
}

/// Attempts the throwing function, defaulting to the handler upon error.
/// - Parameter throwingOperation: A throwing autoclosure to attempt.
/// - Parameter errorHandler: The handler to invoke upon error.
/// - Returns: The result of the throwing operation upon success, or the result of the error handler upon error.
@inlinable
public func attempt<Output>(
    _ throwingOperation: @autoclosure () throws -> Output,
    ifError errorHandler: (Error) -> Output
) -> Output {
    do {
        return try throwingOperation()
    } catch {
        return errorHandler(error)
    }
}

// MARK: - zip

/// Returns a function that runs its input through `f` and `g` and combines
/// the subsequent output values with the given combining function.
/// - Parameter f: The first function to zip.
/// - Parameter g: The second function to zip.
/// - Parameter combine: The function used to combine the output values of `f` and `g`.
/// - Returns: A function that applies both `f` and `g` to its input and
///            returns the result of `combine` on the subsequent output values.
@inlinable
public func zip<Input, Output1, Output2, Combined>(
    _ f: @escaping (Input) -> Output1,
    _ g: @escaping (Input) -> Output2,
    with combine: @escaping (Output1, Output2) -> Combined
) -> (Input) -> Combined {
    return { input in combine(f(input), g(input)) }
}

/// Returns a function from the input type to a tuple
/// containing the results of each of the given functions.
/// - Parameter f: The first function to zip.
/// - Parameter g: The second function to zip.
/// - Returns: A function producing a tuple containing the output values from both `f` and `g`.
@inlinable
public func zip<Input, Output1, Output2>(
    _ f: @escaping (Input) -> Output1,
    _ g: @escaping (Input) -> Output2
) -> (Input) -> (Output1, Output2) {
    return zip(f, g, with: identity)
}

// MARK: - tie

/// Ties together functions with a transformation function.
/// - Parameter f: The first function to tie.
/// - Parameter g: The second function to tie.
/// - Parameter combine: A function combining the output values of `f` and `g`.
/// - Returns: A function from the input values of `f` and `g` the combined result of their output values.
@inlinable
public func tie<Input1, Input2, Output1, Output2, Combined>(
    _ f: @escaping (Input1) -> Output1,
    _ g: @escaping (Input2) -> Output2,
    with combine: @escaping (Output1, Output2) -> Combined
) -> (Input1, Input2) -> Combined {
    return { combine(f($0), g($1)) }
}

/// Ties together functions,
/// transforming a tuple of functions into a function on tuples.
/// - Parameter f: The first function to tie.
/// - Parameter g: The second function to tie.
/// - Returns: A function from the input values of `f` and `g` to the output values of `f` and `g`.
@inlinable
public func tie<Input1, Input2, Output1, Output2>(
    _ f: @escaping (Input1) -> Output1,
    _ g: @escaping (Input2) -> Output2
) -> (Input1, Input2) -> (Output1, Output2) {
    return tie(f, g, with: identity)
}

// MARK: - with

/// Returns the output of the function applied to the given input.
/// - Parameter input: The input to the function.
/// - Parameter transform: The closure to apply to the input.
/// - Returns: The output of the function applied to the input.
@inlinable
public func with<Input, Output>(
    _ input: Input,
    _ transform: (Input) throws -> Output
) rethrows -> Output {
    return try transform(input)
}

/// Mutates the input using the given function.
/// - Parameter input: The input to mutate.
/// - Parameter mutate: The closure to apply in mutating the input.
@inlinable
public func with<Input>(
    _ input: inout Input,
    _ mutate: (inout Input) throws -> Void
) rethrows {
    try mutate(&input)
}

/// Creates a copy of the input, mutates it using the given the function, and returns the result.
/// - Parameter input: The input to copy for mutation.
/// - Parameter mutate: The closure to apply in mutating the copy of the input.
/// - Returns: The mutated copy of the input.
@inlinable
public func with<Input>(
    _ input: Input,
    _ mutate: (inout Input) throws -> Void
) rethrows -> Input {
    var result = input
    try mutate(&result)
    return result
}

/// Mutates the given input reference and returns it.
/// - Parameter input: The input to mutate.
/// - Parameter mutate: The closure to apply in mutating the input.
/// - Returns: The input value after mutation.
@inlinable
@discardableResult
public func with<Input: AnyObject>(
    _ input: Input,
    _ mutate: (Input) throws -> Void
) rethrows -> Input {
    try mutate(input)
    return input
}
