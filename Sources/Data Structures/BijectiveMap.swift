//
//  BijectiveMap.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// A one-to-one map between elements of two sets.
///
/// Given a member of either set, `BijectiveMap` supports lookup of its corresponding member in the other set in constant time.
/// A bijective map can be thought of as a function from the domain to the codomain along with its inverse function.
public struct BijectiveMap<DomainElement: Hashable, CodomainElement: Hashable> {
    @usableFromInline
    internal var _forwardMap: [DomainElement: CodomainElement]

    @usableFromInline
    internal var _inverseMap: [CodomainElement: DomainElement]
}

extension BijectiveMap {
    /// Describes a conflict encountered upon attempting to insert an element into the map.
    public enum InsertionConflict: Error {
        /// Describes an attempt to insert an element in the codomain that already maps to an element in the domain.
        /// The associated value contains the existing domain element to which the codomain element is mapped
        /// along with the new domain element to which a map operation was attempted.
        case conflictingDomainElements(existing: DomainElement, new: DomainElement)

        /// Describes an attempt to insert an element in the domain that already maps to an element in the codomain.
        /// The associated value contains the existing codomain element to which the domain element is mapped
        /// along with the new codomain element to which a map operation was attempted.
        case conflictingCodomainElements(existing: CodomainElement, new: CodomainElement)

        /// Describes an attempt to insert an element whose domain and codomain elements are already mapped to other elements.
        /// The associated value contains the existing domain-codomain element pairs along with the new pair
        /// for which an insert was attempted.
        case conflictingElements(existing: (Element, Element), new: Element)
    }

    /// Describes a resolution to an insertion conflict.
    public enum InsertionConflictResolution {
        /// Describes a decision to keep the existing element rather than insert the new element.
        case chooseExisting

        /// Describes a decision to discard the existing element and insert the new element.
        case chooseNew
    }

    /// Describes a handler invoked to resolve an insertion conflict.
    public typealias InsertionConflictHandler = (InsertionConflict) throws -> InsertionConflictResolution

    @usableFromInline
    internal struct _NotOneToOneError: Error {
        @usableFromInline
        internal init() { }
    }
}

// MARK: - Initialization

extension BijectiveMap {
    @usableFromInline
    internal init(_forwardMap forwardMap: [DomainElement: CodomainElement], inverseMap: [CodomainElement: DomainElement]) {
        _forwardMap = forwardMap
        _inverseMap = inverseMap
    }

    /// Creates an empty map.
    @inlinable
    public init() {
        _forwardMap = [:]
        _inverseMap = [:]
    }

    /// Creates an empty map with preallocated space for at least the specified number of domain-codomain element pairs.
    @inlinable
    public init(minimumCapacity: Int) {
        _forwardMap = Dictionary(minimumCapacity: minimumCapacity)
        _inverseMap = Dictionary(minimumCapacity: minimumCapacity)
    }

    /// Creates a one-to-one map from the given dictionary.
    /// - Parameter map: The key-value pairs to use in creating the map.
    /// - Parameter conflictHandler: The handler invoked in the case of an insertion conflict.
    @inlinable
    public init(
        _ map: [DomainElement: CodomainElement],
        handlingConflictsWith conflictHandler: (DomainElement, DomainElement) throws -> InsertionConflictResolution
    ) rethrows {
        _forwardMap = map
        _inverseMap = Dictionary(minimumCapacity: map.count)
        for (x, y) in map {
            if let existingX = _inverseMap[y] {
                let resolution = try conflictHandler(existingX, x)
                switch resolution {
                case .chooseExisting:
                    continue
                case .chooseNew:
                    _forwardMap.removeValue(forKey: existingX)
                    _inverseMap[y] = x
                }
            } else {
                _inverseMap[y] = x
            }
        }
    }

    /// Creates a two-way one-to-one map if the given dictionary is one-to-one.
    ///
    /// Returns `nil` if the given map is not one-to-one.
    /// - Parameter map: The key-value pairs to use in creating the map.
    @inlinable
    public init?(_ map: [DomainElement: CodomainElement]) {
        do {
            self = try BijectiveMap(map, handlingConflictsWith: { _, _ in throw _NotOneToOneError() })
        } catch {
            return nil
        }
    }

    /// Creates a two-way one-to-one map from the given one-to-one dictionary.
    ///
    /// This initializer will trap if the given dictionary is not one-to-one.
    /// - Parameter map: The one-to-one dictionary to use in creating the map.
    @inlinable
    public init(oneToOneMap map: [DomainElement: CodomainElement]) {
        self.init(map)!
    }

    /// Creates a one-to-one map from the given sequence of pairs.
    /// - Parameter pairs: The element pairs to use in creating the map.
    /// - Parameter conflictHandler: The handler invoked in the case of an insertion conflict.
    @inlinable
    public init<S: Sequence>(
        _ pairs: S,
        handlingConflictsWith conflictHandler: InsertionConflictHandler
    ) rethrows where S.Element == Element {
        self.init(minimumCapacity: pairs.underestimatedCount)
        try merge(with: pairs, handlingConflictsWith: conflictHandler)
    }

    /// Creates a two-way one-to-one map if the given sequence is one-to-one.
    ///
    /// Returns `nil` if the given sequence is not one-to-one.
    /// - Parameter pairs: The element pairs to use in creating the map.
    public init?<S: Sequence>(_ pairs: S) where S.Element == Element {
        do {
            self = try BijectiveMap(pairs, handlingConflictsWith: { throw $0 })
        } catch {
            return nil
        }
    }

    /// Creates a map over the domain using the given transform function.
    /// - Parameter domain: The domain elements to include in the map.
    /// - Parameter transform: The function to apply to a domain element to produce its codomain counterpart.
    /// - Parameter conflictHandler: The handler invoked in the case of an insertion conflict.
    @inlinable
    public init<S: Sequence>(
        domain: S,
        mappingWith transform: (DomainElement) -> CodomainElement,
        handlingConflictsWith conflictHandler: InsertionConflictHandler
    ) rethrows where S.Element == DomainElement {
        let range = domain.map(transform)
        self = try BijectiveMap(zip(domain, range), handlingConflictsWith: conflictHandler)
    }

    /// Creates a map over the domain using the given transform function if its results are one-to-one.
    ///
    /// Returns `nil` if the resulting pairs are not one-to-one.
    /// - Parameter domain: The domain elements to include in the map.
    /// - Parameter transform: The function to apply to a domain element to produce its codomain counterpart.
    @inlinable
    public init?<S: Sequence>(
        domain: S,
        mappingWith transform: (DomainElement) -> CodomainElement
    ) where S.Element == DomainElement {
        do {
            self = try BijectiveMap(domain: domain, mappingWith: transform, handlingConflictsWith: { throw $0 })
        } catch {
            return nil
        }
    }

    /// Reserves enough space to store the specified number of key-value pairs.
    /// If you are adding a known number of domain-codomain element pairs to the map, use this method to avoid multiple reallocations.
    /// This method ensures that the map has unique, mutable, contiguous storage, with space allocated for at least the requested number
    /// of domain-codomain element pairs.
    /// - Parameter minimumCapacity: The requested number of domain-codomain element pairs to store.
    @inlinable
    public mutating func reserveCapacity(_ minimumCapacity: Int) {
        _forwardMap.reserveCapacity(minimumCapacity)
        _inverseMap.reserveCapacity(minimumCapacity)
    }

    /// The total number of domain-codomain element pairs that the map can contain without allocating new storage.
    @inlinable
    public var capacity: Int {
        return Swift.min(_forwardMap.capacity, _inverseMap.capacity)
    }
}

// MARK: - Lookup

extension BijectiveMap {
    /// Returns the counterpart codomain element for the given domain element.
    /// - Parameter domainElement: The domain element to look up in the map.
    /// - Returns: The counterpart codomain element, or `nil` if the domain element is not in the map.
    /// - Complexity: O(1)
    @inlinable
    public func codomainElement(for domainElement: DomainElement) -> CodomainElement? {
        return _forwardMap[domainElement]
    }

    /// Returns the counterpart domain element for the given codomain element.
    /// - Parameter codomainElement: The codomain element to look up in the map.
    /// - Returns: The counterpart domain element, or `nil` if the codomain element is not in the map.
    /// - Complexity: O(1)
    @inlinable
    public func domainElement(for codomainElement: CodomainElement) -> DomainElement? {
        return _inverseMap[codomainElement]
    }

    /// Returns a Boolean value indicating whether the map contains the given domain-codomain element pair.
    /// - Parameter element: The element for which to test containment.
    /// - Returns: `true` if the pair exists in the map; otherwise, `false`.
    /// - Complexity: O(1)
    @inlinable
    public func contains(_ element: Element) -> Bool {
        return _forwardMap[element.0] == element.1
    }

    /// A collection of elements spanning the domain of the map.
    @inlinable
    public var domain: Dictionary<DomainElement, CodomainElement>.Keys {
        return _forwardMap.keys
    }

    /// A collection of elements spanning the range of the map.
    @inlinable
    public var range: Dictionary<CodomainElement, DomainElement>.Keys {
        return _inverseMap.keys
    }
}

// MARK: - Insertion

extension BijectiveMap {
    /// Attempts the insert the given element into the map.
    /// - Parameter element: The element to insert.
    /// - Throws: `InsertionConflictError` if the element could not be inserted.
    @inlinable
    public mutating func insert(_ element: Element) throws {
        try insert(element, handlingConflictsWith: { throw $0 })
    }

    /// Inserts the given element into the map.
    /// - Parameter element: The element to insert.
    /// - Parameter conflictHandler: The handler invoked in case of an insertion conflict.
    @inlinable
    public mutating func insert(
        _ element: Element,
        handlingConflictsWith conflictHandler: InsertionConflictHandler
    ) rethrows {
        let (newX, newY) = element
        let (existingX, existingY) = (_inverseMap[newY], _forwardMap[newX])
        let conflict: InsertionConflict? = {
            switch (existingX, existingY) {
            case (let existingX?, let existingY?):
                return .conflictingElements(existing: ((existingX, newY), (newX, existingY)), new: element)
            case (let existingX?, nil):
                return .conflictingDomainElements(existing: existingX, new: newX)
            case (nil, let existingY?):
                return .conflictingCodomainElements(existing: existingY, new: newY)
            case (nil, nil):
                return nil
            }
        }()

        let resolution = try conflict.map(conflictHandler)
        if case .chooseExisting? = resolution {
            return
        }

        if let existingX = existingX { _forwardMap.removeValue(forKey: existingX) }
        if let existingY = existingY { _inverseMap.removeValue(forKey: existingY) }

        _uncheckedInsert(element)
    }

    @usableFromInline
    internal mutating func _uncheckedInsert(_ element: Element) {
        _forwardMap[element.0] = element.1
        _inverseMap[element.1] = element.0
    }

    /// Returns the counterpart codomain element for the given domain element.
    ///
    /// Uses this subscript's setter removes any existing pair for both the domain element
    /// and the codomain element and inserts the new pair.
    ///
    /// Assigning `nil` via this subscript's setter removes the paired codomain element
    /// for the domain element.
    /// - Parameter domainElement: The domain element to look up in the map.
    /// - Returns: The counterpart codomain element, or `nil` if the domain element is not in the map.
    /// - Complexity: O(1)
    @inlinable
    public subscript(domainElement: DomainElement) -> CodomainElement? {
        get {
            return codomainElement(for: domainElement)
        }
        set {
            guard let newValue = newValue else {
                removePair(forDomainElement: domainElement)
                return
            }
            insert((domainElement, newValue), handlingConflictsWith: { _ in .chooseNew })
        }
    }

    /// Returns the counterpart domain element for the given codomain element.
    ///
    /// Uses this subscript's setter removes any existing pair for both the domain element
    /// and the codomain element and inserts the new pair.
    ///
    /// Assigning `nil` via this subscript's setter removes the paired domain element
    /// for the codomain element.
    /// - Parameter codomainElement: The codomain element to look up in the map.
    /// - Returns: The counterpart domain element, or `nil` if the codomain element is not in the map.
    /// - Complexity: O(1)
    @inlinable
    public subscript(codomainElement: CodomainElement) -> DomainElement? {
        get {
            return domainElement(for: codomainElement)
        }
        set {
            guard let newValue = newValue else {
                removePair(forCodomainElement: codomainElement)
                return
            }
            insert((newValue, codomainElement), handlingConflictsWith: { _ in .chooseNew })
        }
    }

    /// Merges the map with the given sequence of pairs.
    /// - Parameter sequence: The sequence with which to merge.
    /// - Parameter conflictHandler: The handler invoked in the case of an insertion conflict.
    @inlinable
    public mutating func merge<S: Sequence>(
        with sequence: S,
        handlingConflictsWith conflictHandler: InsertionConflictHandler
    ) rethrows where S.Element == Element {
        for element in sequence {
            try insert(element, handlingConflictsWith: conflictHandler)
        }
    }

    /// Returns a new map merged with the given sequence of pairs.
    /// - Parameter sequence: The sequence with which to merge.
    /// - Parameter conflictHandler: The handler invoked in the case of an insertion conflict.
    /// - Returns: A new map merged with the given sequence of pairs.
    @inlinable
    public func merged<S: Sequence>(
        with sequence: S,
        handlingConflictsWith conflictHandler: InsertionConflictHandler
    ) rethrows -> BijectiveMap where S.Element == Element {
        var result = self
        try result.merge(with: sequence, handlingConflictsWith: conflictHandler)
        return result
    }
}

// MARK: - Removal

extension BijectiveMap {
    /// Removes the given domain element and its codomain counterpart.
    /// - Parameter domainElement: The domain element to remove from the map.
    /// - Returns: The removed element, or `nil` if the domain element is not in the map.
    @inlinable
    @discardableResult
    public mutating func removePair(forDomainElement domainElement: DomainElement) -> Element? {
        guard let y = _forwardMap.removeValue(forKey: domainElement) else {
            return nil
        }
        let x = _inverseMap.removeValue(forKey: y)!
        return (x, y)
    }

    /// Removes the given codomain element and its domain counterpart.
    /// - Parameter codomainElement: The codomain element to remove from the map
    /// - Returns: The removed element, or `nil` if the codomain element is not in the map.
    @inlinable
    @discardableResult
    public mutating func removePair(forCodomainElement codomainElement: CodomainElement) -> Element? {
        guard let x = _inverseMap.removeValue(forKey: codomainElement) else {
            return nil
        }
        let y = _forwardMap.removeValue(forKey: x)!
        return (x, y)
    }

    /// Removes all elements matching the given predicate.
    /// - Parameter shouldRemove: A closure that returns `true` if the given element should be removed from the map.
    @inlinable
    public mutating func removeAll(where shouldRemove: (Element) throws -> Bool) rethrows {
        for element in self where try shouldRemove(element) {
            _forwardMap.removeValue(forKey: element.0)
            _inverseMap.removeValue(forKey: element.1)
        }
    }

    /// Removes all key-value pairs from the dictionary.
    /// Calling this method invalidates all indices with respect to the map.
    /// - Parameter keepCapacity: Determines whether the map should keep its underlying buffer. If `true`, the operation preserves
    ///                           the buffer capacity, otherwise the underlying buffer is released. The default value is `false`.
    /// - Complexity: O(*n*), where *n* is the number of domain-codomain element pairs in the map.
    @inlinable
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
        _forwardMap.removeAll(keepingCapacity: keepCapacity)
        _inverseMap.removeAll(keepingCapacity: keepCapacity)
    }

    /// Returns a new map containing the domain-codomain element pairs of the map that satisfy the given predicate.
    /// - Parameter isIncluded: A closure that returns `true` if the given element should be included in the returned map.
    /// - Returns: A map of the pairs that `isIncluded` allows.
    @inlinable
    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> BijectiveMap {
        var result = BijectiveMap()
        for element in self where try isIncluded(element) {
            result._uncheckedInsert(element)
        }
        return result
    }
}

// MARK: - Composition

extension BijectiveMap {
    /// Returns an equivalent one-to-one map with its type parameters swapped.
    ///
    /// The performance of the returned map is equal to this map;
    /// this method is provided strictly as a convenience for swapping the type parameter order.
    /// - Returns: An equivalent one-to-one map with its type parameters swapped.
    /// - Complexity: O(1)
    @inlinable
    public func inverse() -> BijectiveMap<CodomainElement, DomainElement> {
        return .init(_forwardMap: _inverseMap, inverseMap: _forwardMap)
    }

    /// Composes this map with the given map.
    /// - Parameter other: A map between the domain and the new domain.
    /// - Returns: A map between the new domain and the codomain.
    @inlinable
    public func mapDomain<NewDomainElement>(over other: BijectiveMap<DomainElement, NewDomainElement>) -> BijectiveMap<NewDomainElement, CodomainElement> {
        return .init(oneToOneMap: reduce(into: [:]) { forward, pair in
            if let newDomainElement = other[pair.0] {
                forward[newDomainElement] = pair.1
            }
        })
    }

    /// Composes this map with the given map.
    /// - Parameter other: A map between the domain and the new domain.
    /// - Returns: A map between the new domain and the codomain.
    @inlinable
    public func contramapDomain<NewDomainElement>(over other: BijectiveMap<NewDomainElement, DomainElement>) -> BijectiveMap<NewDomainElement, CodomainElement> {
        return mapDomain(over: other.inverse())
    }

    /// Composes this map with the given map.
    /// - Parameter other: A map between the codomain and the new codomain.
    /// - Returns: A map between the domain and the new codomain.
    @inlinable
    public func mapCodomain<NewCodomainElement>(over other: BijectiveMap<CodomainElement, NewCodomainElement>) -> BijectiveMap<DomainElement, NewCodomainElement> {
        return inverse().mapDomain(over: other).inverse()
    }

    /// Composes this map with the given map.
    /// - Parameter other: A map between the codomain and the new codomain.
    /// - Returns: A map between the domain and the new codomain.
    @inlinable
    public func contramapCodomain<NewCodomainElement>(over other: BijectiveMap<NewCodomainElement, CodomainElement>) -> BijectiveMap<DomainElement, NewCodomainElement> {
        return mapCodomain(over: other.inverse())
    }
}

// MARK: - Sequence

extension BijectiveMap: Sequence {
    public struct Iterator: IteratorProtocol {
        public typealias Element = (DomainElement, CodomainElement)

        @usableFromInline
        internal var _iterator: Dictionary<DomainElement, CodomainElement>.Iterator

        @usableFromInline
        internal init(_ iterator: Dictionary<DomainElement, CodomainElement>.Iterator) {
            self._iterator = iterator
        }

        @inlinable
        public mutating func next() -> Element? {
            // Remove the tuple labels from the element produced by the dictionary iterator.
            return _iterator.next().map { pair in (pair.key, pair.value) }
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(_forwardMap.makeIterator())
    }
}

// MARK: - Collection

extension BijectiveMap: Collection {
    public typealias Element = (DomainElement, CodomainElement)
    public typealias Index = Dictionary<DomainElement, CodomainElement>.Index

    @inlinable
    public var startIndex: Index {
        return _forwardMap.startIndex
    }

    @inlinable
    public var endIndex: Index {
        return _forwardMap.endIndex
    }

    @inlinable
    public subscript(position: Index) -> Element {
        return _forwardMap[position]
    }

    @inlinable
    public func index(after i: Index) -> Index {
        return _forwardMap.index(after: i)
    }

    /// The number of domain-codomain element pairs in the map.
    /// - Complexity: O(1)
    @inlinable
    public var count: Int {
        return _forwardMap.count
    }

    @inlinable
    public var isEmpty: Bool {
        return count == 0
    }
}

// MARK: - Equatable

extension BijectiveMap: Equatable {
    @inlinable
    public static func == (lhs: BijectiveMap, rhs: BijectiveMap) -> Bool {
        return lhs._forwardMap == rhs._forwardMap
    }
}

// MARK: - Hashable

extension BijectiveMap: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_forwardMap)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension BijectiveMap: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: Element...) {
        guard let mapping = BijectiveMap(elements) else {
            fatalError("BijectiveMap dictionary literal must be one-to-one.")
        }
        self = mapping
    }
}

// MARK: - CustomStringConvertible, CustomDebugStringConvertible

extension BijectiveMap: CustomStringConvertible, CustomDebugStringConvertible {
    @inlinable
    public var description: String {
        return "BijectiveMap(\(_forwardMap))"
    }

    public var debugDescription: String {
        return description
    }
}

// MARK: - Conditional Conformances
// MARK: - Encodable

extension BijectiveMap: Encodable where DomainElement: Encodable, CodomainElement: Encodable {
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_forwardMap)
    }
}

// MARK: - Decodable

extension BijectiveMap: Decodable where DomainElement: Decodable, CodomainElement: Decodable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let map = try container.decode([DomainElement: CodomainElement].self)
        try self.init(map, handlingConflictsWith: { _, _ in throw _NotOneToOneError() })
    }
}

// MARK: - Testing

extension BijectiveMap {
    internal func assertIsOneToOne() -> Bool {
        guard _forwardMap.count == _inverseMap.count else {
            return false
        }
        for (x, y) in _forwardMap {
            guard _inverseMap[y] == x else {
                return false
            }
        }
        return true
    }
}
