//
//  FixedWidthViewSequence.swift
//  Oxygen
//
//  Created by Michael Pangburn on 9/9/18.
//

/// A view into the adjacent subsequences of a fixed width of an underlying collection.
public struct FixedWidthViewSequence<Base: Collection> {
    @usableFromInline
    internal let _base: Base

    /// The number of elements from the base contained in each view.
    public let viewWidth: Int

    @usableFromInline
    internal init(_base: Base, viewWidth: Int) {
        self._base = _base
        self.viewWidth = viewWidth
    }
}

extension FixedWidthViewSequence: Sequence {
    public typealias Element = Base.SubSequence

    public struct Iterator: IteratorProtocol {
        @usableFromInline
        internal let _base: Base

        @usableFromInline
        internal let _viewWidth: Int

        @usableFromInline
        internal var _subsequenceStartIndex: Base.Index

        @usableFromInline
        internal var _subsequenceEndIndex: Base.Index

        @usableFromInline
        internal var _reachedEnd: Bool

        @usableFromInline
        init(_base: Base, viewWidth: Int) {
            precondition(viewWidth > 0, "\(FixedWidthViewSequence.self) view width must be a positive integer.")
            self._base = _base
            self._viewWidth = viewWidth
            self._subsequenceStartIndex = _base.startIndex
            if let subsequenceEndIndex = _base.index(_base.startIndex, offsetBy: viewWidth, limitedBy: _base.endIndex) {
                self._subsequenceEndIndex = subsequenceEndIndex
                self._reachedEnd = false
            } else {
                self._subsequenceEndIndex = _base.endIndex
                self._reachedEnd = true
            }
        }

        @inlinable
        public mutating func next() -> Element? {
            guard !_reachedEnd else {
                return nil
            }

            defer {
                if _subsequenceEndIndex == _base.endIndex {
                    _reachedEnd = true
                } else {
                    _base.formIndex(after: &_subsequenceStartIndex)
                    _base.formIndex(after: &_subsequenceEndIndex)
                }
            }

            return _base[_subsequenceStartIndex..<_subsequenceEndIndex]
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(_base: _base, viewWidth: viewWidth)
    }
}

extension Collection {
    /// Returns a sequence that iterates over the adjacent subsequences of the collection
    /// with the specified length.
    /// - Parameter viewWidth: The number of elements in each element of the returned sequence.
    /// - Returns: A sequence that iterates over the adjacent subsequences of the collection
    ///            with the specified length.
    @inlinable
    public func adjacentSubsequences(ofLength viewWidth: Int) -> FixedWidthViewSequence<Self> {
        return FixedWidthViewSequence(_base: self, viewWidth: viewWidth)
    }
}
