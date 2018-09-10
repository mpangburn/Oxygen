//
//  FixedWidthViewSequenceTests.swift
//  OxygenTests
//
//  Created by Michael Pangburn on 9/9/18.
//

import XCTest
@testable import Oxygen

class FixedWidthViewSequenceTests: XCTestCase {
    func testFixedWidthViewSequenceEmpty() {
        let empty: [Int] = []
        let groupsOf1 = empty.adjacentSubsequences(ofLength: 1)
        var iterator = groupsOf1.makeIterator()
        XCTAssert(iterator.next() == nil)
    }

    func testFixedWidthViewSequenceFewerElementsThanViewWidth() {
        let threeElements = [1, 2, 3]
        let groupsOfFour = threeElements.adjacentSubsequences(ofLength: 4)
        var iterator = groupsOfFour.makeIterator()
        XCTAssert(iterator.next() == nil)
    }

    func testFixedWidthViewSequenceExactLengthMatch() {
        let threeElements = [1, 2, 3]
        let groupsOfFour = threeElements.adjacentSubsequences(ofLength: 3)
        var iterator = groupsOfFour.makeIterator()
        XCTAssert(iterator.next()!.elementsEqual([1, 2, 3]))
        XCTAssert(iterator.next() == nil)
    }

    func testFixedWidthViewSequence() {
        let groupsOfThree = Array((1...6).adjacentSubsequences(ofLength: 3))
        var iterator = groupsOfThree.makeIterator()
        XCTAssert(iterator.next()!.elementsEqual([1, 2, 3]))
        XCTAssert(iterator.next()!.elementsEqual([2, 3, 4]))
        XCTAssert(iterator.next()!.elementsEqual([3, 4, 5]))
        XCTAssert(iterator.next()!.elementsEqual([4, 5, 6]))
        XCTAssert(iterator.next() == nil)
    }
}
