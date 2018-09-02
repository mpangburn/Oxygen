//
//  Newtype.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/27/18.
//

import protocol Foundation.LocalizedError


/// A new type derived from an existing type.
///
/// `Newtype` provides opt-in default implementations for common Swift protocols,
/// which forward their implementations to those of the conforming raw value.
/// Supported protocols include:
/// - `Equatable`
/// - `Hashable`
/// - `Comparable`
/// - `Error`
/// - `LocalizedError`
/// - `Encodable`
/// - `Decodable`
/// - `LosslessStringConvertible`
/// - `CustomStringConvertible`
/// - `CustomDebugStringConvertible`
/// - `CustomPlaygroundDisplayConvertible`
/// - `ExpressibleByBooleanLiteral`
/// - `ExpressibleByIntegerLiteral`
/// - `ExpressibleByFloatLiteral`
/// - `ExpressibleByUnicodeScalarLiteral`
/// - `ExpressibleByExtendedGraphemeClusterLiteral`
/// - `ExpressibleByStringLiteral`
/// - `Numeric`
/// - `SignedNumeric`
public protocol Newtype: RawRepresentable {
    /// Creates a new instance from the raw value.
    /// - Parameter rawValue: The raw value from which to create the instance.
    init(rawValue: RawValue)
}

// MARK: - Opt-in conformances

extension Newtype where Self: Equatable, RawValue: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension Newtype where Self: Hashable, RawValue: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension Newtype where Self: Comparable, RawValue: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension Newtype where Self: Error, RawValue: Error { }

extension Newtype where Self: LocalizedError, RawValue: LocalizedError {
    @inlinable
    public var errorDescription: String? {
        return rawValue.errorDescription
    }

    @inlinable
    public var failureReason: String? {
        return rawValue.failureReason
    }

    @inlinable
    public var helpAnchor: String? {
        return rawValue.helpAnchor
    }

    @inlinable
    public var recoverySuggestion: String? {
        return rawValue.recoverySuggestion
    }
}

extension Newtype where Self: Encodable, RawValue: Encodable {
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension Newtype where Self: Decodable, RawValue: Decodable {
    @inlinable
    public init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(RawValue.self))
    }
}

extension Newtype where Self: LosslessStringConvertible, RawValue: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        guard let rawValue = RawValue(description) else { return nil }
        self.init(rawValue: rawValue)
    }
}

extension Newtype where Self: CustomStringConvertible {
    @inlinable
    public var description: String {
        return String(describing: rawValue)
    }
}

extension Newtype where Self: CustomDebugStringConvertible {
    @inlinable
    public var debugDescription: String {
        return String(reflecting: rawValue)
    }
}

extension Newtype where Self: CustomPlaygroundDisplayConvertible {
    @inlinable
    public var playgroundDescription: Any {
        return (rawValue as? CustomPlaygroundDisplayConvertible)?.playgroundDescription ?? rawValue
    }
}

// MARK: - ExpressibleBy*Literal

extension Newtype where Self: ExpressibleByBooleanLiteral, RawValue: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = RawValue.BooleanLiteralType

    @inlinable
    public init(booleanLiteral value: RawValue.BooleanLiteralType) {
        self.init(rawValue: RawValue(booleanLiteral: value))
    }
}

extension Newtype where Self: ExpressibleByIntegerLiteral, RawValue: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = RawValue.IntegerLiteralType

    // TODO: Using `Self.IntegerLiteralType` in the argument here produces an error. Reproduce and file.
    @inlinable
    public init(integerLiteral: RawValue.IntegerLiteralType) {
        self.init(rawValue: RawValue(integerLiteral: integerLiteral))
    }
}

extension Newtype where Self: ExpressibleByFloatLiteral, RawValue: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = RawValue.FloatLiteralType

    @inlinable
    public init(floatLiteral: RawValue.FloatLiteralType) {
        self.init(rawValue: RawValue(floatLiteral: floatLiteral))
    }
}

extension Newtype where Self: ExpressibleByUnicodeScalarLiteral, RawValue: ExpressibleByUnicodeScalarLiteral {
    public typealias UnicodeScalarLiteralType = RawValue.UnicodeScalarLiteralType

    @inlinable
    public init(unicodeScalarLiteral: RawValue.UnicodeScalarLiteralType) {
        self.init(rawValue: RawValue(unicodeScalarLiteral: unicodeScalarLiteral))
    }
}

extension Newtype where Self: ExpressibleByExtendedGraphemeClusterLiteral, RawValue: ExpressibleByExtendedGraphemeClusterLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = RawValue.ExtendedGraphemeClusterLiteralType

    @inlinable
    public init(extendedGraphemeClusterLiteral: RawValue.ExtendedGraphemeClusterLiteralType) {
        self.init(rawValue: RawValue(extendedGraphemeClusterLiteral: extendedGraphemeClusterLiteral))
    }
}

extension Newtype where Self: ExpressibleByStringLiteral, RawValue: ExpressibleByStringLiteral {
    public typealias StringLiteralType = RawValue.StringLiteralType

    @inlinable
    public init(stringLiteral: RawValue.StringLiteralType) {
        self.init(rawValue: RawValue(stringLiteral: stringLiteral))
    }
}

// MARK: - Numeric

extension Newtype where Self: Numeric, RawValue: Numeric {
    public typealias Magnitude = RawValue.Magnitude

    @inlinable
    public init?<T>(exactly source: T) where T: BinaryInteger {
        guard let rawValue = RawValue(exactly: source) else { return nil }
        self.init(rawValue: rawValue)
    }

    @inlinable
    public var magnitude: RawValue.Magnitude {
        return rawValue.magnitude
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        return self.init(rawValue: lhs.rawValue + rhs.rawValue)
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }

    @inlinable
    public static func * (lhs: Self, rhs: Self) -> Self {
        return self.init(rawValue: lhs.rawValue * rhs.rawValue)
    }

    @inlinable
    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        return self.init(rawValue: lhs.rawValue - rhs.rawValue)
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

// No requirements for SignedNumeric.
extension Newtype where Self: SignedNumeric, RawValue: SignedNumeric { }

// TODO: Additional integer protocols; String protocols; Collection protocols?
