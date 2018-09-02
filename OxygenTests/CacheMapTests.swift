//
//  CacheMapTests.swift
//  OxygenTests
//
//  Created by Michael Pangburn on 9/2/18.
//

import XCTest
@testable import Oxygen

class CacheMapTests: XCTestCase {
    func testCacheMap() {
        var map = CacheMap<String, String> { $0.uppercased() }
        XCTAssert(map.isEmpty)

        map.cacheOutput(for: "one")
        XCTAssert(map.isOutputCached(for: "one"))
        XCTAssert(map["one"] == "ONE")
        map.clearCachedOutput(for: "one")
        XCTAssert(map.isEmpty)
    }
}
