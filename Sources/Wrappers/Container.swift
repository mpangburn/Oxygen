//
//  Container.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/30/18.
//

/// A type that wraps a single value.
///
/// `Container` provides opt-in default implementations for common Swift protocols,
/// which forward their implementations to those of the conforming value.
/// Supported protocols include:
/// - `Equatable`
/// - `Hashable`
/// - `Encodable`
public protocol Container {
    associatedtype ContainedValue
    var value: ContainedValue { get }
}

extension Container where Self: Equatable, ContainedValue: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}

extension Container where Self: Hashable, ContainedValue: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension Container where Self: Encodable, ContainedValue: Encodable {
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// A container that can be initialized from a value alone.
///
/// In addition to the opt-in default protocol implementations provided by `Container`,
/// `CreatableContainer` supports `Decodable`.
public protocol CreatableContainer: Container {
    init(_ value: ContainedValue)
}

extension CreatableContainer where Self: Decodable, ContainedValue: Decodable {
    @inlinable
    public init(from decoder: Decoder) throws {
        self.init(try decoder.singleValueContainer().decode(ContainedValue.self))
    }
}
