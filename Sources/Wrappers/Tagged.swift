//
//  Tagged.swift
//  Oxygen
//
//  Created by Michael Pangburn on 8/27/18.
//

import protocol Foundation.LocalizedError


/// Ties a type to a phantom tag, providing enhanced compile-time type safety
/// when working with other values of the wrapped type.
///
/// In the following example, `Tagged` is used to distinguish between
/// distinct identifiers, each of which wraps an `Int`:
/// ```
/// struct User {
///     typealias Identifier = Tagged<User, Int>
///     let id: Identifier
/// }
///
/// struct Group {
///     typealias Identifier = Tagged<Group, Int>
///     let id: Identifier
/// }
///
/// func findGroup(withId id: Group.Identifier) -> Group? {
///     /* ... */
/// }
///
/// let user: User = /* ... */
/// findGroup(withId: user.id) // 🛑 Cannot convert value of type 'User.Identifier'
///                            //    (aka 'Tagged<User, Int>') to expected argument
///                            //    type 'Group.Identifier' (aka 'Tagged<Group, Int>')
/// ```
public struct Tagged<Tag, RawValue>: Newtype {
    public var rawValue: RawValue

    @inlinable
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension Tagged {
    /// Transforms the wrapped value using the given function,
    /// retaining the tag type.
    /// - Parameter transform: A closure that takes the raw value of the instance.
    /// - Returns: A `Tagged` instance with the transformed value tied to the original tag type.
    @inlinable
    public func map<NewRawValue>(
        _ transform: (RawValue) throws -> NewRawValue
    ) rethrows -> Tagged<Tag, NewRawValue> {
        return .init(rawValue: try transform(rawValue))
    }
}

// MARK: - Opt-in conformances

extension Tagged: Equatable where RawValue: Equatable { }
extension Tagged: Hashable where RawValue: Hashable { }
extension Tagged: Comparable where RawValue: Comparable { }
extension Tagged: Error where RawValue: Error { }
extension Tagged: LocalizedError where RawValue: LocalizedError { }
extension Tagged: Encodable where RawValue: Encodable { }
extension Tagged: Decodable where RawValue: Decodable { }
extension Tagged: LosslessStringConvertible where RawValue: LosslessStringConvertible { }
extension Tagged: CustomStringConvertible where RawValue: CustomStringConvertible { }
extension Tagged: CustomDebugStringConvertible where RawValue: CustomDebugStringConvertible { }
extension Tagged: CustomPlaygroundDisplayConvertible where RawValue: CustomPlaygroundDisplayConvertible { }
extension Tagged: ExpressibleByBooleanLiteral where RawValue: ExpressibleByBooleanLiteral { }
extension Tagged: ExpressibleByIntegerLiteral where RawValue: ExpressibleByIntegerLiteral { }
extension Tagged: ExpressibleByFloatLiteral where RawValue: ExpressibleByFloatLiteral { }
extension Tagged: ExpressibleByUnicodeScalarLiteral where RawValue: ExpressibleByUnicodeScalarLiteral { }
extension Tagged: ExpressibleByExtendedGraphemeClusterLiteral where RawValue: ExpressibleByExtendedGraphemeClusterLiteral { }
extension Tagged: ExpressibleByStringLiteral where RawValue: ExpressibleByStringLiteral { }
extension Tagged: Numeric where RawValue: Numeric { }
extension Tagged: SignedNumeric where RawValue: SignedNumeric { }
