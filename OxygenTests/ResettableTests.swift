//
//  ResettableTests.swift
//  OxygenTests
//
//  Created by Michael Pangburn on 9/2/18.
//

import XCTest
@testable import Oxygen

class ResettableTests: XCTestCase {
    func testResettableSimple() {
        var backTo42 = Resettable(42)
        XCTAssert(backTo42.value == 42)

        backTo42.value = 1
        XCTAssert(backTo42.value == 1)

        backTo42.reset()
        XCTAssert(backTo42.value == 42)
    }
}
