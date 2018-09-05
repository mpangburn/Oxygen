//
//  CacheMap.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// A map that wraps a function to cache output values once computed.
public final class CacheMap<Input: Hashable, Output> {
    /// The transformation function used to map input values to output values.
    @usableFromInline
    internal let _transform: (Input) -> Output

    /// The cached input-output pairs produced by the transformation.
    @usableFromInline
    internal var _cache: [Input: Output]

    @usableFromInline
    internal init(_transform transform: @escaping (Input) -> Output, cache: [Input: Output]) {
        _transform = transform
        _cache = cache
    }
}

// MARK: - Initialization

extension CacheMap {
    /// Creates a map caching the output values of the given function.
    /// - Parameter transform: A function mapping input values to output values.
    @inlinable
    public convenience init(_ transform: @escaping (Input) -> Output) {
        self.init(_transform: transform, cache: [:])
    }

    /// Creates a map caching the output values of the given function,
    /// reserving space for at least the given number of input-output pairs.
    /// - Parameter minimumCapacity: The number of input-output pairs for which to reserve space.
    /// - Parameter transform: A function mapping input values to output values.
    @inlinable
    public convenience init(minimumCapacity: Int, transform: @escaping (Input) -> Output) {
        self.init(_transform: transform, cache: Dictionary(minimumCapacity: minimumCapacity))
    }

    /// Creates a map caching the output values of the given function,
    /// immediately caching the output values for each element in the sequence.
    /// - Parameter initialValues: A sequence containing input values for which to cache output values.
    /// - Parameter transform: A function mapping input values to output values.
    @inlinable
    public convenience init<S: Sequence>(
        initialValues: S,
        transform: @escaping (Input) -> Output
    ) where S.Element == Input {
        self.init(minimumCapacity: initialValues.underestimatedCount, transform: transform)
        initialValues.forEach { cacheOutput(for: $0) }
    }

    /// Reserves enough space to store the specified number of input-output pairs.
    /// - Parameter minimumCapacity: The requested number of input-output pairs to store.
    @inlinable
    public func reserveCapacity(_ minimumCapacity: Int) {
        _cache.reserveCapacity(minimumCapacity)
    }
}

// MARK: - Caching

extension CacheMap {
    /// Returns the cached output value for the given input value,
    /// or `nil` if no output value has been cached for the input value.
    /// - Parameter input: The input value to look up.
    /// - Returns: The cached output value, or `nil` if the output has not been cached.
    @inlinable
    public func cachedOutput(for input: Input) -> Output? {
        return _cache[input]
    }

    /// Returns `true` is an output value is cached for the given input value, and `false` otherwise.
    /// - Parameter input: The input value to look up.
    /// - Returns: A Boolean value representing whether an output value is cached.
    @inlinable
    public func isOutputCached(for input: Input) -> Bool {
        return cachedOutput(for: input) != nil
    }

    /// Caches the output value for the given input value.
    /// - Parameter input: The input value for which to cache the output value.
    /// - Parameter recomputingIfCached: A Boolean value determining whether the computation should be
    ///                                  reperformed on the input value if an output value is already cached.
    ///                                  The default value is `false`.
    /// - Returns: The output value for the given input value.
    @inlinable
    @discardableResult
    public func cacheOutput(for input: Input, recomputingIfCached shouldRecompute: Bool = false) -> Output {
        if let cachedOutput = self.cachedOutput(for: input), !shouldRecompute {
            return cachedOutput
        } else {
            let output = _transform(input)
            _cache[input] = output
            return output
        }
    }

    /// Returns the output value for the given input value.
    ///
    /// When the output value is accessed for the first time,
    /// the computation is run on the input value, and the result is cached.
    /// If the output value for the given input value has already been cached,
    /// this operation is a nonmutating dictionary lookup.
    /// - Parameter input: The input value for which to retrieve the output value.
    /// - Returns: The output value for the given input value.
    @inlinable
    public subscript(input: Input) -> Output {
        return cacheOutput(for: input)
    }
}

// MARK: - Removal

extension CacheMap {
    /// Clears the cached output value for the given input value.
    /// - Parameter input: The input value for which to remove the output value.
    /// - Returns: The removed output value, or `nil` if no output value was cached for the input value.
    @inlinable
    @discardableResult
    public func clearCachedOutput(for input: Input) -> Output? {
        return _cache.removeValue(forKey: input)
    }

    /// Removes all cached input-output pairs satisfying the given predicate.
    /// - Parameter shouldRemove: A function determining whether an input-output pair should be removed from the cache.
    @inlinable
    public func clearCache(where shouldRemove: (Element) throws -> Bool) rethrows {
        for element in self where try shouldRemove(element) {
            clearCachedOutput(for: element.input)
        }
    }

    /// Removes all cached input-output pairs.
    /// - Parameter keepCapacity: Determines whether the map should keep its underlying buffer. If `true`, the operation preserves
    ///                           the buffer capacity, otherwise the underlying buffer is released. The default value is `false`.
    /// - Complexity: O(*n*), where *n* is the number of cached input-output pairs in the map.
    @inlinable
    public func clearCache(keepingCapacity keepCapacity: Bool = false) {
        _cache.removeAll(keepingCapacity: keepCapacity)
    }

    /// Returns a new map containing the cached input-output pairs of the map that satisfy the given predicate.
    /// - Parameter isIncluded: A closure that returns `true` if the given element should be included in the returned map.
    /// - Returns: A map of the pairs that `isIncluded` allows.
    @inlinable
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> CacheMap {
        let result = CacheMap(_transform)
        result._cache = try _cache.filter(isIncluded)
        return result
    }
}

// MARK: - Sequence

extension CacheMap: Sequence {
    /// An iterator over the cached elements in the map.
    public struct Iterator: IteratorProtocol {
        public typealias Element = (input: Input, output: Output)

        @usableFromInline
        internal var _iterator: Dictionary<Input, Output>.Iterator

        @usableFromInline
        internal init(_ iterator: Dictionary<Input, Output>.Iterator) {
            self._iterator = iterator
        }

        @inlinable
        public mutating func next() -> Element? {
            return _iterator.next().map { (input: $0.key, output: $0.value) }
        }
    }

    /// Returns an iterator over the cached elements in the map.
    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(_cache.makeIterator())
    }
}

// MARK: - Collection

extension CacheMap: Collection {
    public typealias Element = (input: Input, output: Output)
    public typealias Index = Dictionary<Input, Output>.Index

    @inlinable
    public var startIndex: Index {
        return _cache.startIndex
    }

    @inlinable
    public var endIndex: Index {
        return _cache.endIndex
    }

    @inlinable
    public subscript(position: Index) -> Element {
        return _cache[position] as (Input, Output) as Element
    }

    @inlinable
    public func index(after i: Index) -> Index {
        return _cache.index(after: i)
    }

    /// The number of cached input-output element pairs in the map.
    /// - Complexity: O(1)
    @inlinable
    public var count: Int {
        return _cache.count
    }

    @inlinable
    public var isEmpty: Bool {
        return count == 0
    }
}
