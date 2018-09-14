//
//  Comparable.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

import enum Foundation.ComparisonResult


extension Comparable {
    /// Compares this instance to another.
    /// - Parameter other: The value with which to compare.
    /// - Returns: The result of the comparison.
    @inlinable
    public func compare(to other: Self) -> ComparisonResult {
        if self < other {
            return .orderedAscending
        } else if self > other {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
}

extension Comparable {
    /// Returns `self` clamped to the given range.
    ///
    /// If `self` is greater than the range's upper bound, this function returns the range's upper bound.
    /// If `self` falls within the range, this function returns `self`.
    /// If `self` is less than the range's lower bound, this function returns the range's lower bound.
    /// - Parameter range: The range providing the bounds for clamping.
    /// - Returns: `self` clamped to the bounds of the range.
    @inlinable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        if self < range.lowerBound {
            return range.lowerBound
        } else if self > range.upperBound {
            return range.upperBound
        } else {
            return self
        }
    }

    /// Clamps `self` to the given range.
    ///
    /// If `self` is greater than the range's upper bound, `self` is assigned to the range's upper bound.
    /// If `self` falls within the range, `self` is unmodified.
    /// If `self` is less than the range's lower bound, `self` is assigned to the range's lower bound.
    /// - Parameter range: The range providing the bounds for clamping.
    @inlinable
    public mutating func clamp(to range: ClosedRange<Self>) {
        self = clamped(to: range)
    }

    /// Returns `self` clamped to the given range.
    ///
    /// If `self` is greater than the range's upper bound, this function returns the range's upper bound.
    /// If `self` falls within the range, this function returns `self`.
    /// - Parameter range: The range providing the upper bound for clamping.
    /// - Returns: `self` clamped to the upper bound of the range.
    @inlinable
    public func clamped(to range: PartialRangeThrough<Self>) -> Self {
        return min(self, range.upperBound)
    }

    /// Returns `self` clamped to the given range.
    ///
    /// If `self` is greater than the range's upper bound, this function returns the range's upper bound.
    /// If `self` falls within the range, this function returns `self`.
    /// If `self` is less than the range's lower bound, this function returns the range's lower bound.
    /// - Parameter range: The range providing the bounds for clamping.
    /// - Returns: `self` clamped to the bounds of the range.
    /// - Parameter range: The range providing the upper bound for clamping.
    @inlinable
    public mutating func clamp(to range: PartialRangeThrough<Self>) {
        self = clamped(to: range)
    }

    /// Returns `self` clamped to the given range.
    ///
    /// If `self` is less than the range's lower bound, this function returns the range's lower bound.
    /// If `self` falls within the range, this function returns `self`.
    /// - Parameter range: The range providing the lower bound for clamping.
    /// - Returns: `self` clamped to the lower bound of the range.
    @inlinable
    public func clamped(to range: PartialRangeFrom<Self>) -> Self {
        return max(self, range.lowerBound)
    }

    /// Clamps `self` to the given range.
    ///
    /// If `self` falls within the range, `self` is unmodified.
    /// If `self` is less than the range's lower bound, `self` is assigned to the range's lower bound.
    /// - Parameter range: The range providing the lower bound for clamping.
    @inlinable
    public mutating func clamp(to range: PartialRangeFrom<Self>) {
        self = clamped(to: range)
    }
}
