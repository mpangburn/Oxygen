//
//  Sequence.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/1/18.
//

/// Creates a sequence of tuples built out of three underlying sequences.
/// - Parameter sequence1: The first sequence to zip.
/// - Parameter sequence2: The second sequence to zip.
/// - Parameter sequence3: The third sequence to zip.
/// - Returns: A sequence of tuples, where the elements of each tuple
///            are corresponding elements of the three sequences.
public func zip<Sequence1, Sequence2, Sequence3>(
    _ sequence1: Sequence1,
    _ sequence2: Sequence2,
    _ sequence3: Sequence3
) -> Zip3Sequence<Sequence1, Sequence2, Sequence3> {
    return Zip3Sequence(_sequence1: sequence1, _sequence2: sequence2, _sequence3: sequence3)
}

/// A sequence of tuples built out of three underlying sequences.
public struct Zip3Sequence<Sequence1: Sequence, Sequence2: Sequence, Sequence3: Sequence>: Sequence {
    @usableFromInline
    internal let _sequence1: Sequence1
    @usableFromInline
    internal let _sequence2: Sequence2
    @usableFromInline
    internal let _sequence3: Sequence3

    @usableFromInline
    internal init(
        _sequence1 sequence1: Sequence1,
        _sequence2 sequence2: Sequence2,
        _sequence3 sequence3: Sequence3
    ) {
        (_sequence1, _sequence2, _sequence3) = (sequence1, sequence2, sequence3)
    }

    public struct Iterator: IteratorProtocol {
        public typealias Element = (Sequence1.Element, Sequence2.Element, Sequence3.Element)

        @usableFromInline
        internal var _baseStream1: Sequence1.Iterator
        @usableFromInline
        internal var _baseStream2: Sequence2.Iterator
        @usableFromInline
        internal var _baseStream3: Sequence3.Iterator
        @usableFromInline
        internal var _reachedEnd: Bool = false

        @usableFromInline
        internal init(
            _ iterator1: Sequence1.Iterator,
            _ iterator2: Sequence2.Iterator,
            _ iterator3: Sequence3.Iterator
        ) {
            (_baseStream1, _baseStream2, _baseStream3) = (iterator1, iterator2, iterator3)
        }

        @inlinable
        public mutating func next() -> Element? {
            if _reachedEnd {
                return nil
            }

            guard
                let element1 = _baseStream1.next(),
                let element2 = _baseStream2.next(),
                let element3 = _baseStream3.next()
            else {
                _reachedEnd = true
                return nil
            }

            return (element1, element2, element3)
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(
            _sequence1.makeIterator(),
            _sequence2.makeIterator(),
            _sequence3.makeIterator()
        )
    }
}

