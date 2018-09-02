//
//  LazyTests.swift
//  OxygenTests
//
//  Created by Michael Pangburn on 9/2/18.
//

import XCTest
@testable import Oxygen

class LazyTests: XCTestCase {
    func testLazy() {
        var count = 0

        var lazilyIncrementCount = Lazy { count += 1 }
        XCTAssert(count == 0)

        // map should not trigger evaluation
        _ = lazilyIncrementCount.map { /* nothing */ }
        XCTAssert(count == 0)

        // zip should not trigger evaluation
        var zippedBeforeEvaluation = zip(lazilyIncrementCount, lazilyIncrementCount)
        XCTAssert(count == 0)

        // evaluation should happen only once
        _ = lazilyIncrementCount.value
        XCTAssert(count == 1)
        _ = lazilyIncrementCount.value
        XCTAssert(count == 1)

        // zip after evaluation should not re-trigger evaluation
        var zippedAfterEvaluation = zip(lazilyIncrementCount, lazilyIncrementCount)
        _ = zippedAfterEvaluation.value
        XCTAssert(count == 1)

        // state before evaluation should have been captured, so evaluation re-triggered
        _ = zippedBeforeEvaluation.value
        XCTAssert(count == 3)

        // clearing should cause re-evaluation
        lazilyIncrementCount.clear()
        _ = lazilyIncrementCount.value
        XCTAssert(count == 4)
    }
}
