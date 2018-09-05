//
//  NonemptyCollection.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/4/18.
//

// With inspiration from Point-Free:
// https://github.com/pointfreeco/swift-nonempty
// Though it makes good use of the type system,
// the Point-Free implementation suffers from significant
// performance hits, particularly when collections containing
// unique elements (Set, Dictionary) are involved.

// The following implementation sacrifices the type system guarantee
// of non-emptiness in favor of improved performance.
// If a reference type collection is wrapped and mutated to become
// empty, a runtime error can occur.
// Because most collections (including all of those in the Standard Library)
// are value types, this is rarely an issue in practice.

extension Collection {
    /// Returns a validated nonempty collection, or `nil`
    /// if the collection is empty.
    ///
    /// Because a `NonemptyCollection` is guaranteed to contain at least
    /// one element, a number of `Collection` operations that
    /// typically return `Optional` values can instead return
    /// non-`Optional` values.
    ///
    /// ```
    /// let possiblyEmptyValues: [Int] = /* ... */
    /// if let nonemptyValues = possiblyEmptyValues.nonempty() {
    ///     let first = nonemptyValues.first // Int, not Optional<Int>
    ///     let min = nonemptyValues.min() // Int, not Optional<Int>
    /// }
    /// ```
    /// - Returns: A `NonemptyCollection` wrapping the collection
    ///            if it contains at least one element, or `nil`
    ///            if the collection is empty.
    /// - Warning: If the collection is a reference type and is
    ///            externally mutated such that it becomes empty,
    ///            a runtime error may occur in using a
    ///            `NonemptyCollection` wrapping the collection.
    @inlinable
    public func nonempty() -> NonemptyCollection<Self>? {
        return NonemptyCollection(self)
    }
}

/// An array guaranteed to contain at least one element.
public typealias NonemptyArray<Element> = NonemptyCollection<[Element]>

/// An set guaranteed to contain at least one element.
public typealias NonemptySet<Element: Hashable> = NonemptyCollection<Set<Element>>

/// An dictionary guaranteed to contain at least one key-value pair.
public typealias NonemptyDictionary<Key: Hashable, Value> = NonemptyCollection<[Key: Value]>

/// A collection guaranteed to contain at least one element.
///
/// Because a `NonemptyCollection` is guaranteed to contain at least
/// one element, a number of `Collection` operations that
/// typically return `Optional` values can instead return
/// non-`Optional` values.
///
/// ```
/// let possiblyEmptyValues: [Int] = /* ... */
/// if let nonemptyValues = possiblyEmptyValues.nonempty() {
///     let first = nonemptyValues.first // Int, not Optional<Int>
///     let min = nonemptyValues.min() // Int, not Optional<Int>
/// }
public struct NonemptyCollection<Base: Collection> {
    @usableFromInline
    internal var _base: Base

    @usableFromInline
    internal init?(_ base: Base) {
        guard !base.isEmpty else {
            return nil
        }
        _base = base
    }

    @usableFromInline
    internal init(_unchecked base: Base) {
        _base = base
    }
}

// MARK: - Protocol requirement/customization point forwarding

// MARK: - Sequence

extension NonemptyCollection: Sequence {
    public typealias Element = Base.Element
    public typealias SubSequence = Base.SubSequence
    public typealias Iterator = Base.Iterator

    @inlinable
    public func makeIterator() -> Iterator {
        return _base.makeIterator()
    }
}

// MARK: - Collection

extension NonemptyCollection: Collection {
    public typealias Index = Base.Index
    public typealias Indices = Base.Indices

    @inlinable
    public var startIndex: Index {
        return _base.startIndex
    }

    @inlinable
    public var endIndex: Index {
        return _base.endIndex
    }

    @inlinable
    public func index(after i: Index) -> Index {
        return _base.index(after: i)
    }

    @inlinable
    public func formIndex(after i: inout Index) {
        _base.formIndex(after: &i)
    }

    @inlinable
    public func index(_ i: Index, offsetBy distance: Int) -> Index {
        return _base.index(i, offsetBy: distance)
    }

    @inlinable
    public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
        return _base.index(i, offsetBy: distance, limitedBy: limit)
    }

    @inlinable
    public func distance(from start: Index, to end: Index) -> Int {
        return _base.distance(from: start, to: end)
    }

    @inlinable
    public subscript(position: Index) -> Element {
        return _base[position]
    }

    @inlinable
    public subscript(bounds: Range<Index>) -> SubSequence {
        return _base[bounds]
    }

    @inlinable
    public var indices: Indices {
        return _base.indices
    }

    @inlinable
    public func prefix(upTo end: Index) -> SubSequence {
        return _base.prefix(upTo: end)
    }

    @inlinable
    public func prefix(through position: Index) -> SubSequence {
        return _base.prefix(through: position)
    }

    @inlinable
    public func suffix(from start: Index) -> SubSequence {
        return _base.suffix(from: start)
    }

    @inlinable
    public var isEmpty: Bool {
        // Unfortunately, if `Base` is a reference type,
        // it's possible that the wrapped collection *could* become empty.
        // Point-Free uses the type system to prevent this
        // (c.f. https://github.com/pointfreeco/swift-nonempty/blob/master/Sources/NonEmpty/NonEmpty.swift),
        // but this has significant performance implications when working with
        // collections of unique elements (Set and Dictionary).
        return false
    }

    @inlinable
    public var count: Int {
        return _base.count
    }
}

// MARK: - Nonempty-specific perks

extension NonemptyCollection {
    /// The first element of the collection.
    @inlinable
    public var first: Element {
        return _base.first!
    }

    /// Returns the minimum element in the sequence, using the given predicate as
    /// the comparison between elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// This example shows how to use the `min(by:)` method on a
    /// dictionary to find the key-value pair with the lowest value.
    ///
    ///     let hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     let leastHue = hues.min { a, b in a.value < b.value }
    ///     print(leastHue)
    ///     // Prints "Optional(("Coral", 16))"
    ///
    /// - Parameter areInIncreasingOrder: A predicate that returns `true`
    ///   if its first argument should be ordered before its second
    ///   argument; otherwise, `false`.
    /// - Returns: The sequence's minimum element, according to
    ///   `areInIncreasingOrder`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    @warn_unqualified_access
    public func min(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element {
        return try _base.min(by: areInIncreasingOrder)!
    }

    /// Returns the maximum element in the sequence, using the given predicate
    /// as the comparison between elements.
    ///
    /// The predicate must be a *strict weak ordering* over the elements. That
    /// is, for any elements `a`, `b`, and `c`, the following conditions must
    /// hold:
    ///
    /// - `areInIncreasingOrder(a, a)` is always `false`. (Irreflexivity)
    /// - If `areInIncreasingOrder(a, b)` and `areInIncreasingOrder(b, c)` are
    ///   both `true`, then `areInIncreasingOrder(a, c)` is also
    ///   `true`. (Transitive comparability)
    /// - Two elements are *incomparable* if neither is ordered before the other
    ///   according to the predicate. If `a` and `b` are incomparable, and `b`
    ///   and `c` are incomparable, then `a` and `c` are also incomparable.
    ///   (Transitive incomparability)
    ///
    /// This example shows how to use the `max(by:)` method on a
    /// dictionary to find the key-value pair with the highest value.
    ///
    ///     let hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     let greatestHue = hues.max { a, b in a.value < b.value }
    ///     print(greatestHue)
    ///     // Prints "Optional(("Heliotrope", 296))"
    ///
    /// - Parameter areInIncreasingOrder:  A predicate that returns `true` if its
    ///   first argument should be ordered before its second argument;
    ///   otherwise, `false`.
    /// - Returns: The sequence's maximum element, according to
    ///   `areInIncreasingOrder`.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    @warn_unqualified_access
    public func max(by areInIncreasingOrder: (Element, Element) throws -> Bool) rethrows -> Element {
        return try _base.max(by: areInIncreasingOrder)!
    }

    /// Returns a nonempty array containing the results of mapping the given closure
    /// over the sequence's elements.
    ///
    /// In this example, `map` is used first to convert the names in the array
    /// to lowercase strings and then to count their characters.
    ///
    ///     let cast = ["Vivien", "Marlon", "Kim", "Karl"]
    ///     let lowercaseNames = cast.map { $0.lowercased() }
    ///     // 'lowercaseNames' == ["vivien", "marlon", "kim", "karl"]
    ///     let letterCounts = cast.map { $0.count }
    ///     // 'letterCounts' == [6, 6, 3, 4]
    ///
    /// - Parameter transform: A mapping closure. `transform` accepts an
    ///   element of this sequence as its parameter and returns a transformed
    ///   value of the same or of a different type.
    /// - Returns: An array containing the transformed elements of this
    ///   sequence.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func map<NewElement>(_ transform: (Element) throws -> NewElement) rethrows -> NonemptyCollection<[NewElement]> {
        return .init(_unchecked: try _base.map(transform))
    }

    /// Returns a random element of the collection, using the given generator as a source for randomness.
    /// - Parameter generator: The random number generator to use when choosing a random element.
    @inlinable
    public func randomElement<Generator: RandomNumberGenerator>(using generator: inout Generator) -> Element {
        return _base.randomElement(using: &generator)!
    }

    /// Returns a random element of the collection.
    @inlinable
    public func randomElement() -> Element? {
        return _base.randomElement()!
    }

    /// Returns the elements of the sequence, shuffled using the given generator
    /// as a source for randomness.
    ///
    /// You use this method to randomize the elements of a sequence when you are
    /// using a custom random number generator. For example, you can shuffle the
    /// numbers between `0` and `9` by calling the `shuffled(using:)` method on
    /// that range:
    ///
    ///     let numbers = 0...9
    ///     let shuffledNumbers = numbers.shuffled(using: &myGenerator)
    ///     // shuffledNumbers == [8, 9, 4, 3, 2, 6, 7, 0, 5, 1]
    ///
    /// - Parameter generator: The random number generator to use when shuffling
    ///   the sequence.
    /// - Returns: An array of this sequence's elements in a shuffled order.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    /// - Note: The algorithm used to shuffle a sequence may change in a future
    ///   version of Swift. If you're passing a generator that results in the
    ///   same shuffled order each time you run your program, that sequence may
    ///   change when your program is compiled using a different version of
    ///   Swift.
    @inlinable
    public func shuffled<Generator: RandomNumberGenerator>(using generator: inout Generator) -> NonemptyCollection<[Element]> {
        return .init(_unchecked: _base.shuffled(using: &generator))
    }

    /// Returns the elements of the sequence, shuffled.
    ///
    /// For example, you can shuffle the numbers between `0` and `9` by calling
    /// the `shuffled()` method on that range:
    ///
    ///     let numbers = 0...9
    ///     let shuffledNumbers = numbers.shuffled()
    ///     // shuffledNumbers == [1, 7, 6, 2, 8, 9, 4, 3, 5, 0]
    ///
    /// This method is equivalent to calling `shuffled(using:)`, passing in the
    /// system's default random generator.
    ///
    /// - Returns: A shuffled array of this sequence's elements.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func shuffled() -> NonemptyCollection<[Element]> {
        return .init(_unchecked: _base.shuffled())
    }
}

// Note: using `where Element: Comparable` produces a compile-time error here.
// TODO: Reproduce and file.
extension NonemptyCollection where Base.Element: Comparable {
    @inlinable
    public func min() -> Element {
        return _base.min()!
    }

    @inlinable
    public func max() -> Element {
        return _base.max()!
    }

    @inlinable
    public func sorted() -> NonemptyCollection<[Element]> {
        return .init(_unchecked: _base.sorted())
    }
}

// MARK: - Conditional Conformances

// MARK: - Bidirectional Collection

extension NonemptyCollection: BidirectionalCollection where Base: BidirectionalCollection {
    @inlinable
    public func index(before i: Index) -> Index {
        return _base.index(before: i)
    }

    @inlinable
    public func formIndex(before i: inout Index) {
        _base.formIndex(before: &i)
    }
}

extension NonemptyCollection where Base: BidirectionalCollection {
    /// The last element of the collection.
    @inlinable
    public var last: Element {
        return _base.last!
    }
}

// MARK: - MutableCollection

extension NonemptyCollection: MutableCollection where Base: MutableCollection {
    @inlinable
    public subscript(position: Index) -> Element {
        get {
            return _base[position]
        }
        set {
            _base[position] = newValue
        }
    }

    @inlinable
    public subscript(bounds: Range<Index>) -> SubSequence {
        get {
            return _base[bounds]
        }
        set {
            _base[bounds] = newValue
        }
    }

    @inlinable
    public mutating func partition(by belongsInSecondPartition: (Element) throws -> Bool) rethrows -> Index {
        return try _base.partition(by: belongsInSecondPartition)
    }

    @inlinable
    public mutating func swapAt(_ i: Index, _ j: Index) {
        _base.swapAt(i, j)
    }
}

// MARK: - RangeReplaceableCollection
// Note: NonemptyCollection can't conform to RangeReplaceableCollection
//       of `init()` and the removal requirements.
//       Instead, we'll mimic the RangeReplacebleCollection API.

extension NonemptyCollection {
    /// An error thrown when a removal of elements is attempted
    /// that would result in an empty collection.
    @usableFromInline
    internal struct _InsufficientElementsForRemovalError: Error {
        @usableFromInline
        internal init() { }
    }
}

extension NonemptyCollection where Base: RangeReplaceableCollection {
    /// Replaces the specified subrange of elements with the given collection.
    ///
    /// This method has the effect of removing the specified range of elements
    /// from the collection and inserting the new elements at the same location.
    /// The number of new elements need not match the number of elements being
    /// removed.
    ///
    /// In this example, three elements in the middle of an array of integers are
    /// replaced by the five elements of a `Repeated<Int>` instance.
    ///
    ///      var nums = [10, 20, 30, 40, 50]
    ///      nums.replaceSubrange(1...3, with: repeatElement(1, count: 5))
    ///      print(nums)
    ///      // Prints "[10, 1, 1, 1, 1, 1, 50]"
    ///
    /// If you pass a zero-length range as the `subrange` parameter, this method
    /// inserts the elements of `newElements` at `subrange.startIndex`. Calling
    /// the `insert(contentsOf:at:)` method instead is preferred.
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameters:
    ///   - subrange: The subrange of the collection to replace. The bounds of
    ///     the range must be valid indices of the collection.
    ///   - newElements: The new elements to add to the collection.
    ///
    /// - Complexity: O(*n* + *m*), where *n* is length of this collection and
    ///   *m* is the length of `newElements`. If the call to this method simply
    ///   appends the contents of `newElements` to the collection, this method is
    ///   equivalent to `append(contentsOf:)`.
    @inlinable
    public mutating func replaceSubrange<C: Collection>(
        _ subrange: Range<Index>,
        with newElements: NonemptyCollection<C>
    ) where C.Element == Element {
        _base.replaceSubrange(subrange, with: newElements)
    }

    /// Prepares the collection to store the specified number of elements, when
    /// doing so is appropriate for the underlying type.
    ///
    /// If you are adding a known number of elements to a collection, use this
    /// method to avoid multiple reallocations. A type that conforms to
    /// `RangeReplaceableCollection` can choose how to respond when this method
    /// is called. Depending on the type, it may make sense to allocate more or
    /// less storage than requested, or to take no action at all.
    ///
    /// - Parameter n: The requested number of elements to store.
    @inlinable
    public mutating func reserveCapacity(_ n: Int) {
        _base.reserveCapacity(n)
    }

    /// Adds an element to the end of the collection.
    ///
    /// If the collection does not have sufficient capacity for another element,
    /// additional storage is allocated before appending `newElement`. The
    /// following example adds a new number to an array of integers:
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers.append(100)
    ///
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 4, 5, 100]"
    ///
    /// - Parameter newElement: The element to append to the collection.
    ///
    /// - Complexity: O(1) on average, over many calls to `append(_:)` on the
    ///   same collection.
    @inlinable
    public mutating func append(_ newElement: Element) {
        _base.append(newElement)
    }

    /// Adds the elements of a sequence or collection to the end of this
    /// collection.
    ///
    /// The collection being appended to allocates any additional necessary
    /// storage to hold the new elements.
    ///
    /// The following example appends the elements of a `Range<Int>` instance to
    /// an array of integers:
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers.append(contentsOf: 10...15)
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15]"
    ///
    /// - Parameter newElements: The elements to append to the collection.
    ///
    /// - Complexity: O(*m*), where *m* is the length of `newElements`.
    @inlinable
    public mutating func append<S: Sequence>(contentsOf newElements: S) where S.Element == Element {
        _base.append(contentsOf: newElements)
    }

    /// Inserts a new element into the collection at the specified position.
    ///
    /// The new element is inserted before the element currently at the
    /// specified index. If you pass the collection's `endIndex` property as
    /// the `index` parameter, the new element is appended to the
    /// collection.
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers.insert(100, at: 3)
    ///     numbers.insert(200, at: numbers.endIndex)
    ///
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 100, 4, 5, 200]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter newElement: The new element to insert into the collection.
    /// - Parameter i: The position at which to insert the new element.
    ///   `index` must be a valid index into the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection. If
    ///   `i == endIndex`, this method is equivalent to `append(_:)`.
    @inlinable
    public mutating func insert(_ newElement: Element, at i: Index) {
        _base.insert(newElement, at: i)
    }

    /// Inserts the elements of a sequence into the collection at the specified
    /// position.
    ///
    /// The new elements are inserted before the element currently at the
    /// specified index. If you pass the collection's `endIndex` property as the
    /// `index` parameter, the new elements are appended to the collection.
    ///
    /// Here's an example of inserting a range of integers into an array of the
    /// same type:
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers.insert(contentsOf: 100...103, at: 3)
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 100, 101, 102, 103, 4, 5]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter newElements: The new elements to insert into the collection.
    /// - Parameter i: The position at which to insert the new elements. `index`
    ///   must be a valid index of the collection.
    ///
    /// - Complexity: O(*n* + *m*), where *n* is length of this collection and
    ///   *m* is the length of `newElements`. If `i == endIndex`, this method
    ///   is equivalent to `append(contentsOf:)`.
    @inlinable
    public mutating func insert<C: Collection>(contentsOf newElements: C, at i: Index) where C.Element == Element {
        _base.insert(contentsOf: newElements, at: i)
    }

    /// Removes and returns the element at the specified position.
    /// Throws an error if the collection contains only one element.
    ///
    /// All the elements following the specified position are moved to close the
    /// gap. This example removes the middle element from an array of
    /// measurements.
    ///
    ///     var measurements = [1.2, 1.5, 2.9, 1.2, 1.6]
    ///     let removed = measurements.remove(at: 2)
    ///     print(measurements)
    ///     // Prints "[1.2, 1.5, 1.2, 1.6]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter i: The position of the element to remove. `index` must be
    ///   a valid index of the collection that is not equal to the collection's
    ///   end index.
    /// - Returns: The removed element.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    @discardableResult
    public mutating func remove(at i: Index) throws -> Element {
        guard countExcedes(1) else {
            throw _InsufficientElementsForRemovalError()
        }
        return _base.remove(at: i)
    }

    /// Removes the specified subrange of elements from the collection.
    /// An error is thrown if the removal would result in an empty collection.
    ///
    ///     var bugs = ["Aphid", "Bumblebee", "Cicada", "Damselfly", "Earwig"]
    ///     bugs.removeSubrange(1...3)
    ///     print(bugs)
    ///     // Prints "["Aphid", "Earwig"]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter bounds: The subrange of the collection to remove. The bounds
    ///   of the range must be valid indices of the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func removeSubrange(_ bounds: Range<Index>) throws {
        guard countExcedes(self[bounds].count) else {
            throw _InsufficientElementsForRemovalError()
        }
        _base.removeSubrange(bounds)
    }

    /// Removes and returns the first element of the collection.
    /// Throws an error if the collection contains only one element.
    ///
    /// The collection must not be empty.
    ///
    ///     var bugs = ["Aphid", "Bumblebee", "Cicada", "Damselfly", "Earwig"]
    ///     bugs.removeFirst()
    ///     print(bugs)
    ///     // Prints "["Bumblebee", "Cicada", "Damselfly", "Earwig"]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Returns: The removed element.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    @discardableResult
    public mutating func removeFirst() throws -> Element {
        guard countExcedes(1) else {
            throw _InsufficientElementsForRemovalError()
        }
        return _base.removeFirst()
    }

    /// Removes the specified number of elements from the beginning of the
    /// collection.
    /// Throws an error if the requested number of elements to remove is
    /// greater than the number of elements in the collection.
    ///
    ///     var bugs = ["Aphid", "Bumblebee", "Cicada", "Damselfly", "Earwig"]
    ///     bugs.removeFirst(3)
    ///     print(bugs)
    ///     // Prints "["Damselfly", "Earwig"]"
    ///
    /// Calling this method may invalidate any existing indices for use with this
    /// collection.
    ///
    /// - Parameter k: The number of elements to remove from the collection.
    ///   `k` must be greater than or equal to zero and must not exceed the
    ///   number of elements in the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func removeFirst(_ k: Int) throws {
        guard countExcedes(k) else {
            throw _InsufficientElementsForRemovalError()
        }
        _base.removeFirst(k)
    }

    /// Creates a new collection by concatenating the elements of a collection and
    /// a sequence.
    ///
    /// The two arguments must have the same `Element` type. For example, you can
    /// concatenate the elements of an integer array and a `Range<Int>` instance.
    ///
    ///     let numbers = [1, 2, 3, 4]
    ///     let moreNumbers = numbers + 5...10
    ///     print(moreNumbers)
    ///     // Prints "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
    ///
    /// The resulting collection has the type of the argument on the left-hand
    /// side. In the example above, `moreNumbers` has the same type as `numbers`,
    /// which is `[Int]`.
    ///
    /// - Parameters:
    ///   - lhs: A range-replaceable collection.
    ///   - rhs: A collection or finite sequence.
    @inlinable
    public static func + <Other: Sequence> (lhs: NonemptyCollection, rhs: Other) -> NonemptyCollection where Element == Other.Element {
        var lhs = lhs
        lhs.reserveCapacity(lhs.count + rhs.underestimatedCount)
        lhs.append(contentsOf: rhs)
        return lhs
    }

    /// Creates a new collection by concatenating the elements of a sequence and a
    /// collection.
    ///
    /// The two arguments must have the same `Element` type. For example, you can
    /// concatenate the elements of a `Range<Int>` instance and an integer array.
    ///
    ///     let numbers = [7, 8, 9, 10]
    ///     let moreNumbers = 1...6 + numbers
    ///     print(moreNumbers)
    ///     // Prints "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"
    ///
    /// The resulting collection has the type of argument on the right-hand side.
    /// In the example above, `moreNumbers` has the same type as `numbers`, which
    /// is `[Int]`.
    ///
    /// - Parameters:
    ///   - lhs: A collection or finite sequence.
    ///   - rhs: A range-replaceable collection.
    @inlinable
    public static func + <Other: Sequence> (lhs: Other, rhs: NonemptyCollection) -> NonemptyCollection where Element == Other.Element {
        return rhs + lhs
    }

    /// Appends the elements of a sequence to a range-replaceable collection.
    ///
    /// Use this operator to append the elements of a sequence to the end of
    /// range-replaceable collection with same `Element` type. This example
    /// appends the elements of a `Range<Int>` instance to an array of integers.
    ///
    ///     var numbers = [1, 2, 3, 4, 5]
    ///     numbers += 10...15
    ///     print(numbers)
    ///     // Prints "[1, 2, 3, 4, 5, 10, 11, 12, 13, 14, 15]"
    ///
    /// - Parameters:
    ///   - lhs: The collection to append to.
    ///   - rhs: A collection or finite sequence.
    ///
    /// - Complexity: O(*m*), where *m* is the length of the right-hand-side argument.
    @inlinable
    public static func += <Other: Sequence> (lhs: inout NonemptyCollection, rhs: Other) where Element == Other.Element {
        lhs.append(contentsOf: rhs)
    }
}

extension NonemptyCollection where Base: RangeReplaceableCollection, Base: BidirectionalCollection {
    /// Removes and returns the last element of the collection.
    /// Throws an error if the collection contains only one element.
    ///
    /// Calling this method may invalidate all saved indices of this
    /// collection. Do not rely on a previously stored index value after
    /// altering a collection with any operation that can change its length.
    ///
    /// - Returns: The last element of the collection.
    ///
    /// - Complexity: O(1)
    @inlinable
    @discardableResult
    public mutating func removeLast() throws -> Element {
        guard countExcedes(1) else {
            throw _InsufficientElementsForRemovalError()
        }
        return _base.removeLast()
    }

    /// Removes the specified number of elements from the end of the
    /// collection.
    ///
    /// An error is thrown if the removal would result in an empty collection.
    ///
    /// Calling this method may invalidate all saved indices of this
    /// collection. Do not rely on a previously stored index value after
    /// altering a collection with any operation that can change its length.
    ///
    /// - Parameter k: The number of elements to remove from the collection.
    ///   `k` must be greater than or equal to zero and must not exceed the
    ///   number of elements in the collection.
    ///
    /// - Complexity: O(*k*), where *k* is the specified number of elements.
    @inlinable
    public mutating func removeLast(_ k: Int) throws {
        guard countExcedes(k) else {
            throw _InsufficientElementsForRemovalError()
        }
        _base.removeLast(k)
    }
}

// MARK: - RandomAccessCollection

extension NonemptyCollection: RandomAccessCollection where Base: RandomAccessCollection { }

// MARK: - SetAlgebra
// Note: NonemptyCollection can't conform to SetAlgebra, so we'll just mimic some of its functionality.

extension NonemptyCollection where Base: SetAlgebra {
    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    ///
    /// This example uses the `contains(_:)` method to test whether an integer is
    /// a member of a set of prime numbers.
    ///
    ///     let primes: Set = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
    ///     let x = 5
    ///     if primes.contains(x) {
    ///         print("\(x) is prime!")
    ///     } else {
    ///         print("\(x). Not prime.")
    ///     }
    ///     // Prints "5 is prime!"
    ///
    /// - Parameter member: An element to look for in the set.
    /// - Returns: `true` if `member` exists in the set; otherwise, `false`.
    @inlinable
    public func contains(_ member: Element) -> Bool {
        return _base.contains(member)
    }

    /// Returns a new set with the elements of both this and the given set.
    ///
    /// In the following example, the `attendeesAndVisitors` set is made up
    /// of the elements of the `attendees` and `visitors` sets:
    ///
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Marcia", "Nathaniel"]
    ///     let attendeesAndVisitors = attendees.union(visitors)
    ///     print(attendeesAndVisitors)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     let initialIndices = Set(0..<5)
    ///     let expandedIndices = initialIndices.union([2, 3, 6, 7])
    ///     print(expandedIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set with the unique elements of this set and `other`.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    @inlinable
    public func union(_ other: NonemptyCollection) -> NonemptyCollection {
        return union(other._base)
    }

    /// Returns a new set with the elements of both this and the given set.
    ///
    /// In the following example, the `attendeesAndVisitors` set is made up
    /// of the elements of the `attendees` and `visitors` sets:
    ///
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Marcia", "Nathaniel"]
    ///     let attendeesAndVisitors = attendees.union(visitors)
    ///     print(attendeesAndVisitors)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     let initialIndices = Set(0..<5)
    ///     let expandedIndices = initialIndices.union([2, 3, 6, 7])
    ///     print(expandedIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set with the unique elements of this set and `other`.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    @inlinable
    public func union(_ other: Base) -> NonemptyCollection {
        return .init(_unchecked: _base.union(other))
    }

    /// Returns a new set with the elements that are common to both this set and
    /// the given set.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    @inlinable
    public func intersection(_ other: NonemptyCollection) -> Base {
        return intersection(other._base)
    }

    /// Returns a new set with the elements that are common to both this set and
    /// the given set.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    @inlinable
    public func intersection(_ other: Base) -> Base {
        return _base.intersection(other)
    }

    /// Returns a new set with the elements that are either in this set or in the
    /// given set, but not in both.
    ///
    /// In the following example, the `eitherNeighborsOrEmployees` set is made up
    /// of the elements of the `employees` and `neighbors` sets that are not in
    /// both `employees` *and* `neighbors`. In particular, the names `"Bethany"`
    /// and `"Eric"` do not appear in `eitherNeighborsOrEmployees`.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     let eitherNeighborsOrEmployees = employees.symmetricDifference(neighbors)
    ///     print(eitherNeighborsOrEmployees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    @inlinable
    public func symmetricDifference(_ other: NonemptyCollection) -> Base {
        return symmetricDifference(other._base)
    }

    /// Returns a new set with the elements that are either in this set or in the
    /// given set, but not in both.
    ///
    /// In the following example, the `eitherNeighborsOrEmployees` set is made up
    /// of the elements of the `employees` and `neighbors` sets that are not in
    /// both `employees` *and* `neighbors`. In particular, the names `"Bethany"`
    /// and `"Eric"` do not appear in `eitherNeighborsOrEmployees`.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     let eitherNeighborsOrEmployees = employees.symmetricDifference(neighbors)
    ///     print(eitherNeighborsOrEmployees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    @inlinable
    public func symmetricDifference(_ other: Base) -> Base {
        return _base.symmetricDifference(other)
    }

    /// Inserts the given element in the set if it is not already present.
    ///
    /// If an element equal to `newMember` is already contained in the set, this
    /// method has no effect. In this example, a new element is inserted into
    /// `classDays`, a set of days of the week. When an existing element is
    /// inserted, the `classDays` set does not change.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.wednesday, .friday]
    ///     print(classDays.insert(.monday))
    ///     // Prints "(true, .monday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    ///     print(classDays.insert(.friday))
    ///     // Prints "(false, .friday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Returns: `(true, newMember)` if `newMember` was not contained in the
    ///   set. If an element equal to `newMember` was already contained in the
    ///   set, the method returns `(false, oldMember)`, where `oldMember` is the
    ///   element that was equal to `newMember`. In some cases, `oldMember` may
    ///   be distinguishable from `newMember` by identity comparison or some
    ///   other means.
    @inlinable
    @discardableResult
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        return _base.insert(newMember)
    }

    /// Removes the given element and any elements subsumed by the given element.
    /// Throws an error if the requested element to remove is the last remaining element in the set.
    ///
    /// - Parameter member: The element of the set to remove.
    /// - Returns: For ordinary sets, an element equal to `member` if `member` is
    ///   contained in the set; otherwise, `nil`. In some cases, a returned
    ///   element may be distinguishable from `newMember` by identity comparison
    ///   or some other means.
    @inlinable
    @discardableResult
    public mutating func remove(_ member: Element) throws -> Element? {
        if !countExcedes(1) && contains(member) {
            throw _InsufficientElementsForRemovalError()
        }
        return _base.remove(member)
    }

    /// Inserts the given element into the set unconditionally.
    ///
    /// If an element equal to `newMember` is already contained in the set,
    /// `newMember` replaces the existing element. In this example, an existing
    /// element is inserted into `classDays`, a set of days of the week.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.monday, .wednesday, .friday]
    ///     print(classDays.update(with: .monday))
    ///     // Prints "Optional(.monday)"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Returns: For ordinary sets, an element equal to `newMember` if the set
    ///   already contained such a member; otherwise, `nil`. In some cases, the
    ///   returned element may be distinguishable from `newMember` by identity
    ///   comparison or some other means.
    @inlinable
    @discardableResult
    public mutating func update(with newMember: Element) -> Element? {
        return _base.update(with: newMember)
    }

    /// Adds the elements of the given set to the set.
    ///
    /// In the following example, the elements of the `visitors` set are added to
    /// the `attendees` set:
    ///
    ///     var attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors: Set = ["Diana", "Marcia", "Nathaniel"]
    ///     attendees.formUnion(visitors)
    ///     print(attendees)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     var initialIndices = Set(0..<5)
    ///     initialIndices.formUnion([2, 3, 6, 7])
    ///     print(initialIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    @inlinable
    public mutating func formUnion(_ other: NonemptyCollection) {
        formUnion(other._base)
    }

    /// Adds the elements of the given set to the set.
    ///
    /// In the following example, the elements of the `visitors` set are added to
    /// the `attendees` set:
    ///
    ///     var attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors: Set = ["Diana", "Marcia", "Nathaniel"]
    ///     attendees.formUnion(visitors)
    ///     print(attendees)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     var initialIndices = Set(0..<5)
    ///     initialIndices.formUnion([2, 3, 6, 7])
    ///     print(initialIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    @inlinable
    public mutating func formUnion(_ other: Base) {
        _base.formUnion(other)
    }

    /// Returns a new set containing the elements of this set that do not occur
    /// in the given set.
    ///
    /// In the following example, the `nonNeighbors` set is made up of the
    /// elements of the `employees` set that are not elements of `neighbors`:
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let nonNeighbors = employees.subtracting(neighbors)
    ///     print(nonNeighbors)
    ///     // Prints "["Diana", "Chris", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    @inlinable
    public func subtracting(_ other: NonemptyCollection) -> Base {
        return subtracting(other._base)
    }

    /// Returns a new set containing the elements of this set that do not occur
    /// in the given set.
    ///
    /// In the following example, the `nonNeighbors` set is made up of the
    /// elements of the `employees` set that are not elements of `neighbors`:
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let nonNeighbors = employees.subtracting(neighbors)
    ///     print(nonNeighbors)
    ///     // Prints "["Diana", "Chris", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    @inlinable
    public func subtracting(_ other: Base) -> Base {
        return _base.subtracting(other)
    }

    /// Returns a Boolean value that indicates whether the set is a subset of
    /// another set.
    ///
    /// Set *A* is a subset of another set *B* if every member of *A* is also a
    /// member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isSubset(of: employees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
    @inlinable
    public func isSubset(of other: NonemptyCollection) -> Bool {
        return isSubset(of: other._base)
    }

    /// Returns a Boolean value that indicates whether the set is a subset of
    /// another set.
    ///
    /// Set *A* is a subset of another set *B* if every member of *A* is also a
    /// member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isSubset(of: employees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a subset of `other`; otherwise, `false`.
    @inlinable
    public func isSubset(of other: Base) -> Bool {
        return _base.isSubset(of: other)
    }

    /// Returns a Boolean value that indicates whether the set has no members in
    /// common with the given set.
    ///
    /// In the following example, the `employees` set is disjoint with the
    /// `visitors` set because no name appears in both sets.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let visitors: Set = ["Marcia", "Nathaniel", "Olivia"]
    ///     print(employees.isDisjoint(with: visitors))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set has no elements in common with `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isDisjoint(with other: NonemptyCollection) -> Bool {
        return isDisjoint(with: other._base)
    }

    /// Returns a Boolean value that indicates whether the set has no members in
    /// common with the given set.
    ///
    /// In the following example, the `employees` set is disjoint with the
    /// `visitors` set because no name appears in both sets.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let visitors: Set = ["Marcia", "Nathaniel", "Olivia"]
    ///     print(employees.isDisjoint(with: visitors))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set has no elements in common with `other`;
    ///   otherwise, `false`.
    @inlinable
    public func isDisjoint(with other: Base) -> Bool {
        return _base.isDisjoint(with: other)
    }

    /// Returns a Boolean value that indicates whether the set is a superset of
    /// the given set.
    ///
    /// Set *A* is a superset of another set *B* if every member of *B* is also a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isSuperset(of: attendees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a superset of `possibleSubset`;
    ///   otherwise, `false`.
    @inlinable
    public func isSuperset(of other: NonemptyCollection) -> Bool {
        return isSuperset(of: other._base)
    }

    /// Returns a Boolean value that indicates whether the set is a superset of
    /// the given set.
    ///
    /// Set *A* is a superset of another set *B* if every member of *B* is also a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isSuperset(of: attendees))
    ///     // Prints "true"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a superset of `possibleSubset`;
    ///   otherwise, `false`.
    @inlinable
    public func isSuperset(of other: Base) -> Bool {
        return _base.isSuperset(of: other)
    }

    /// Returns a Boolean value that indicates whether this set is a strict
    /// superset of the given set.
    ///
    /// Set *A* is a strict superset of another set *B* if every member of *B* is
    /// also a member of *A* and *A* contains at least one element that is *not*
    /// a member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isStrictSuperset(of: attendees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict superset of itself:
    ///     print(employees.isStrictSuperset(of: employees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a strict superset of `other`; otherwise,
    ///   `false`.
    @inlinable
    public func isStrictSuperset(of other: NonemptyCollection) -> Bool {
        return isStrictSuperset(of: other._base)
    }

    /// Returns a Boolean value that indicates whether this set is a strict
    /// superset of the given set.
    ///
    /// Set *A* is a strict superset of another set *B* if every member of *B* is
    /// also a member of *A* and *A* contains at least one element that is *not*
    /// a member of *B*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(employees.isStrictSuperset(of: attendees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict superset of itself:
    ///     print(employees.isStrictSuperset(of: employees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a strict superset of `other`; otherwise,
    ///   `false`.
    @inlinable
    public func isStrictSuperset(of other: Base) -> Bool {
        return _base.isStrictSuperset(of: other)
    }

    /// Returns a Boolean value that indicates whether this set is a strict
    /// subset of the given set.
    ///
    /// Set *A* is a strict subset of another set *B* if every member of *A* is
    /// also a member of *B* and *B* contains at least one element that is not a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isStrictSubset(of: employees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict subset of itself:
    ///     print(attendees.isStrictSubset(of: attendees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a strict subset of `other`; otherwise,
    ///   `false`.
    @inlinable
    public func isStrictSubset(of other: NonemptyCollection) -> Bool {
        return isStrictSubset(of: other._base)
    }

    /// Returns a Boolean value that indicates whether this set is a strict
    /// subset of the given set.
    ///
    /// Set *A* is a strict subset of another set *B* if every member of *A* is
    /// also a member of *B* and *B* contains at least one element that is not a
    /// member of *A*.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     print(attendees.isStrictSubset(of: employees))
    ///     // Prints "true"
    ///
    ///     // A set is never a strict subset of itself:
    ///     print(attendees.isStrictSubset(of: attendees))
    ///     // Prints "false"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: `true` if the set is a strict subset of `other`; otherwise,
    ///   `false`.
    @inlinable
    public func isStrictSubset(of other: Base) -> Bool {
        return _base.isStrictSubset(of: other)
    }
}

// MARK: - Dictionary helpers

public protocol _DictionaryProtocol: Collection where Element == (key: Key, value: Value) {
    associatedtype Key: Hashable
    associatedtype Value

    var keys: Dictionary<Key, Value>.Keys { get }
    var values: Dictionary<Key, Value>.Values { get }

    subscript(key: Key) -> Value? { get }
    mutating func updateValue(_ value: Value, forKey key: Key) -> Value?

    mutating func merge<S: Sequence>(
        _ other: S,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows where S.Element == (Key, Value)
    mutating func merge(
        _ other: [Key: Value],
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows

    mutating func removeValue(forKey key: Key) -> Value?

    mutating func reserveCapacity(_ n: Int)
}

extension Dictionary: _DictionaryProtocol { }

extension NonemptyCollection where Base: _DictionaryProtocol {
    /// A collection containing just the keys of the dictionary.
    ///
    /// When iterated over, keys appear in this collection in the same order as
    /// they occur in the dictionary's key-value pairs. Each key in the keys
    /// collection has a unique value.
    ///
    ///     let countryCodes = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "JP": "Japan", "GH": "Ghana"]"
    ///
    ///     for k in countryCodes.keys {
    ///         print(k)
    ///     }
    ///     // Prints "BR"
    ///     // Prints "JP"
    ///     // Prints "GH"
    @inlinable
    public var keys: NonemptyCollection<Dictionary<Base.Key, Base.Value>.Keys> {
        return .init(_unchecked: _base.keys)
    }

    /// A collection containing just the values of the dictionary.
    ///
    /// When iterated over, values appear in this collection in the same order as
    /// they occur in the dictionary's key-value pairs.
    ///
    ///     let countryCodes = ["BR": "Brazil", "GH": "Ghana", "JP": "Japan"]
    ///     print(countryCodes)
    ///     // Prints "["BR": "Brazil", "JP": "Japan", "GH": "Ghana"]"
    ///
    ///     for v in countryCodes.values {
    ///         print(v)
    ///     }
    ///     // Prints "Brazil"
    ///     // Prints "Japan"
    ///     // Prints "Ghana"
    @inlinable
    public var values: NonemptyCollection<Dictionary<Base.Key, Base.Value>.Values> {
        return .init(_unchecked: _base.values)
    }

    /// Accesses the value associated with the given key for reading.
    ///
    /// This *key-based* subscript returns the value for the given key if the key
    /// is found in the dictionary, or `nil` if the key is not found.
    ///
    /// The following example creates a new dictionary and prints the value of a
    /// key found in the dictionary (`"Coral"`) and a key not found in the
    /// dictionary (`"Cerise"`).
    ///
    ///     var hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     print(hues["Coral"])
    ///     // Prints "Optional(16)"
    ///     print(hues["Cerise"])
    ///     // Prints "nil"
    ///
    /// When you assign a value for a key and that key already exists, the
    /// dictionary overwrites the existing value. If the dictionary doesn't
    /// contain the key, the key and value are added as a new key-value pair.
    ///
    /// Here, the value for the key `"Coral"` is updated from `16` to `18` and a
    /// new key-value pair is added for the key `"Cerise"`.
    ///
    ///     hues["Coral"] = 18
    ///     print(hues["Coral"])
    ///     // Prints "Optional(18)"
    ///
    ///     hues["Cerise"] = 330
    ///     print(hues["Cerise"])
    ///     // Prints "Optional(330)"
    ///
    /// - Parameter key: The key to find in the dictionary.
    /// - Returns: The value associated with `key` if `key` is in the dictionary;
    ///   otherwise, `nil`.
    @inlinable
    public subscript(key: Base.Key) -> Base.Value? {
        return _base[key]
    }

    /// Updates the value stored in the dictionary for the given key, or adds a
    /// new key-value pair if the key does not exist.
    ///
    /// Use this method instead of key-based subscripting when you need to know
    /// whether the new value supplants the value of an existing key. If the
    /// value of an existing key is updated, `updateValue(_:forKey:)` returns
    /// the original value.
    ///
    ///     var hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///
    ///     if let oldValue = hues.updateValue(18, forKey: "Coral") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     }
    ///     // Prints "The old value of 16 was replaced with a new one."
    ///
    /// If the given key is not present in the dictionary, this method adds the
    /// key-value pair and returns `nil`.
    ///
    ///     if let oldValue = hues.updateValue(330, forKey: "Cerise") {
    ///         print("The old value of \(oldValue) was replaced with a new one.")
    ///     } else {
    ///         print("No value was found in the dictionary for that key.")
    ///     }
    ///     // Prints "No value was found in the dictionary for that key."
    ///
    /// - Parameters:
    ///   - value: The new value to add to the dictionary.
    ///   - key: The key to associate with `value`. If `key` already exists in
    ///     the dictionary, `value` replaces the existing associated value. If
    ///     `key` isn't already a key of the dictionary, the `(key, value)` pair
    ///     is added.
    /// - Returns: The value that was replaced, or `nil` if a new key-value pair
    ///   was added.
    @inlinable
    public mutating func updateValue(_ value: Base.Value, forKey key: Base.Key) -> Base.Value? {
        return _base.updateValue(value, forKey: key)
    }

    /// Merges the key-value pairs in the given sequence into the dictionary,
    /// using a combining closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs are merged with the dictionary, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(zip(["a", "c"], [3, 4])) { (current, _) in current }
    ///     // ["b": 2, "a": 1, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     dictionary.merge(zip(["a", "d"], [5, 6])) { (_, new) in new }
    ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    @inlinable
    public mutating func merge<S: Sequence>(
        _ other: S,
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows where S.Element == (Base.Key, Base.Value) {
        try _base.merge(other, uniquingKeysWith: combine)
    }

    /// Merges the given dictionary into this dictionary, using a combining
    /// closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// dictionary, or to combine existing and new values. As the key-values
    /// pairs in `other` are merged with this dictionary, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(["a": 3, "c": 4]) { (current, _) in current }
    ///     // ["b": 2, "a": 1, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     dictionary.merge(["a": 5, "d": 6]) { (_, new) in new }
    ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  A dictionary to merge.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    @inlinable
    public mutating func merge(
        _ other: [Base.Key: Base.Value],
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows {
        try _base.merge(other, uniquingKeysWith: combine)
    }

    /// Merges the given dictionary into this dictionary, using a combining
    /// closure to determine the value for any duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the updated
    /// dictionary, or to combine existing and new values. As the key-values
    /// pairs in `other` are merged with this dictionary, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     var dictionary = ["a": 1, "b": 2]
    ///
    ///     // Keeping existing value for key "a":
    ///     dictionary.merge(["a": 3, "c": 4]) { (current, _) in current }
    ///     // ["b": 2, "a": 1, "c": 4]
    ///
    ///     // Taking the new value for key "a":
    ///     dictionary.merge(["a": 5, "d": 6]) { (_, new) in new }
    ///     // ["b": 2, "a": 5, "c": 4, "d": 6]
    ///
    /// - Parameters:
    ///   - other:  A dictionary to merge.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    @inlinable
    public mutating func merge(
        _ other: NonemptyCollection,
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows {
        try merge(other._base as! [Base.Key: Base.Value], uniquingKeysWith: combine)
    }

    /// Creates a dictionary by merging key-value pairs in a sequence into the
    /// dictionary, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs are merged with the dictionary, the `combine` closure is called
    /// with the current and new values for any duplicate keys that are
    /// encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary = ["a": 1, "b": 2]
    ///     let newKeyValues = zip(["a", "b"], [3, 4])
    ///
    ///     let keepingCurrent = dictionary.merging(newKeyValues) { (current, _) in current }
    ///     // ["b": 2, "a": 1]
    ///     let replacingCurrent = dictionary.merging(newKeyValues) { (_, new) in new }
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - other:  A sequence of key-value pairs.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    /// - Returns: A new dictionary with the combined keys and values of this
    ///   dictionary and `other`.
    @inlinable
    public func merging<S: Sequence>(
        _ other: S,
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows -> NonemptyCollection where S.Element == (Base.Key, Base.Value) {
        var result = self
        try result.merge(other, uniquingKeysWith: combine)
        return result
    }

    /// Creates a dictionary by merging the given dictionary into this
    /// dictionary, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs in `other` are merged with this dictionary, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary = ["a": 1, "b": 2]
    ///     let otherDictionary = ["a": 3, "b": 4]
    ///
    ///     let keepingCurrent = dictionary.merging(otherDictionary)
    ///           { (current, _) in current }
    ///     // ["b": 2, "a": 1]
    ///     let replacingCurrent = dictionary.merging(otherDictionary)
    ///           { (_, new) in new }
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - other:  A dictionary to merge.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    /// - Returns: A new dictionary with the combined keys and values of this
    ///   dictionary and `other`.
    @inlinable
    public func merging(
        _ other: [Base.Key: Base.Value],
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows -> NonemptyCollection {
        var result = self
        try result.merge(other, uniquingKeysWith: combine)
        return result
    }

    /// Creates a dictionary by merging the given dictionary into this
    /// dictionary, using a combining closure to determine the value for
    /// duplicate keys.
    ///
    /// Use the `combine` closure to select a value to use in the returned
    /// dictionary, or to combine existing and new values. As the key-value
    /// pairs in `other` are merged with this dictionary, the `combine` closure
    /// is called with the current and new values for any duplicate keys that
    /// are encountered.
    ///
    /// This example shows how to choose the current or new values for any
    /// duplicate keys:
    ///
    ///     let dictionary = ["a": 1, "b": 2]
    ///     let otherDictionary = ["a": 3, "b": 4]
    ///
    ///     let keepingCurrent = dictionary.merging(otherDictionary)
    ///           { (current, _) in current }
    ///     // ["b": 2, "a": 1]
    ///     let replacingCurrent = dictionary.merging(otherDictionary)
    ///           { (_, new) in new }
    ///     // ["b": 4, "a": 3]
    ///
    /// - Parameters:
    ///   - other:  A dictionary to merge.
    ///   - combine: A closure that takes the current and new values for any
    ///     duplicate keys. The closure returns the desired value for the final
    ///     dictionary.
    /// - Returns: A new dictionary with the combined keys and values of this
    ///   dictionary and `other`.
    @inlinable
    public func merging(
        _ other: NonemptyCollection,
        uniquingKeysWith combine: (Base.Value, Base.Value) throws -> Base.Value
    ) rethrows -> NonemptyCollection {
        return try merging(other._base as! [Base.Key: Base.Value], uniquingKeysWith: combine)
    }

    /// Removes the given key and its associated value from the dictionary.
    /// Throws an error if the dictionary contains only a single key-value pair
    /// whose key matches the key to remove.
    ///
    /// If the key is found in the dictionary, this method returns the key's
    /// associated value. On removal, this method invalidates all indices with
    /// respect to the dictionary.
    ///
    ///     var hues = ["Heliotrope": 296, "Coral": 16, "Aquamarine": 156]
    ///     if let value = hues.removeValue(forKey: "Coral") {
    ///         print("The value \(value) was removed.")
    ///     }
    ///     // Prints "The value 16 was removed."
    ///
    /// If the key isn't found in the dictionary, `removeValue(forKey:)` returns
    /// `nil`.
    ///
    ///     if let value = hues.removeValueForKey("Cerise") {
    ///         print("The value \(value) was removed.")
    ///     } else {
    ///         print("No value found for that key.")
    ///     }
    ///     // Prints "No value found for that key.""
    ///
    /// - Parameter key: The key to remove along with its associated value.
    /// - Returns: The value that was removed, or `nil` if the key was not
    ///   present in the dictionary.
    ///
    /// - Complexity: O(*n*), where *n* is the number of key-value pairs in the
    ///   dictionary.
    @inlinable
    @discardableResult
    public mutating func removeValue(forKey key: Base.Key) throws -> Base.Value? {
        if count == 1, self[key] != nil {
            throw _InsufficientElementsForRemovalError()
        }
        return _base.removeValue(forKey: key)
    }

    /// Reserves enough space to store the specified number of key-value pairs.
    ///
    /// If you are adding a known number of key-value pairs to a dictionary, use this
    /// method to avoid multiple reallocations. This method ensures that the
    /// dictionary has unique, mutable, contiguous storage, with space allocated
    /// for at least the requested number of key-value pairs.
    ///
    /// Calling the `reserveCapacity(_:)` method on a dictionary with bridged
    /// storage triggers a copy to contiguous storage even if the existing
    /// storage has room to store `minimumCapacity` key-value pairs.
    ///
    /// - Parameter minimumCapacity: The requested number of key-value pairs to
    ///   store.
    @inlinable
    public mutating func reserveCapacity(_ n: Int) {
        _base.reserveCapacity(n)
    }
}

// MARK: - Equatable

extension NonemptyCollection: Equatable where Base: Equatable { }

// MARK: - Hashable

extension NonemptyCollection: Hashable where Base: Hashable { }

// MARK: - Decodable

extension NonemptyCollection: Decodable where Base: Decodable { }

// MARK: - Encodable

extension NonemptyCollection: Encodable where Base: Encodable { }
