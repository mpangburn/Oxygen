//
//  BijectiveMapTests.swift
//  OxygenTests
//
//  Created by Michael Pangburn on 9/2/18.
//

import XCTest
@testable import Oxygen

class BijectiveMapTests: XCTestCase {
    func testOneToOneInit() {
        let oneToOneDict = [
            1: "one",
            2: "two",
            3: "three"
        ]
        let map = BijectiveMap(oneToOneDict, handlingConflictsWith: { _, _ in
            XCTFail(); return .chooseNew
        })

        XCTAssert(map[1] == "one")
        XCTAssert(map["one"] == 1)
        XCTAssert(map[2] == "two")
        XCTAssert(map["two"] == 2)
        XCTAssert(map[3] == "three")
        XCTAssert(map["three"] == 3)
        XCTAssert(map.assertIsOneToOne())
    }

    func testInsert() {
        var map: BijectiveMap = [
            1: "one",
            2: "two",
            3: "three"
        ]

        // no conflict
        map.insert((4, "four"), handlingConflictsWith: { _ in
            XCTFail(); return .chooseNew
        })

        XCTAssert(map.assertIsOneToOne())

        // conflicting codomain elements, choose new
        map.insert((1, "ONE"), handlingConflictsWith: { conflict in
            guard case .conflictingCodomainElements(_) = conflict else {
                XCTFail(); return .chooseNew
            }
            return .chooseNew
        })
        XCTAssert(map[1] == "ONE")
        XCTAssert(map["ONE"] == 1)
        XCTAssert(map["one"] == nil)
        XCTAssert(map.assertIsOneToOne())

        // conflicting codomain elements, choose existing
        map.insert((1, "one"), handlingConflictsWith: { conflict in
            guard case .conflictingCodomainElements(_) = conflict else {
                XCTFail(); return .chooseExisting
            }
            return .chooseExisting
        })
        XCTAssert(map[1] == "ONE")
        XCTAssert(map["ONE"] == 1)
        XCTAssert(map["one"] == nil)
        XCTAssert(map.assertIsOneToOne())

        // conflicting domain elements, choose new
        map.insert((-1, "ONE"), handlingConflictsWith: { conflict in
            guard case .conflictingDomainElements(_) = conflict else {
                XCTFail(); return .chooseNew
            }
            return .chooseNew
        })
        XCTAssert(map[-1] == "ONE")
        XCTAssert(map["ONE"] == -1)
        XCTAssert(map[1] == nil)
        XCTAssert(map.assertIsOneToOne())

        // conflicting domain elements, choose existing
        map.insert((1, "ONE"), handlingConflictsWith: { conflict in
            guard case .conflictingDomainElements(_) = conflict else {
                XCTFail(); return .chooseExisting
            }
            return .chooseExisting
        })
        XCTAssert(map[-1] == "ONE")
        XCTAssert(map["ONE"] == -1)
        XCTAssert(map[1] == nil)
        XCTAssert(map.assertIsOneToOne())

        // conflicting elements, choose new
        map.insert((-1, "four"), handlingConflictsWith: { conflict in
            guard case .conflictingElements(_) = conflict else {
                XCTFail(); return .chooseNew
            }
            return .chooseNew
        })
        XCTAssert(map[-1] == "four")
        XCTAssert(map["four"] == -1)
        XCTAssert(map["ONE"] == nil)
        XCTAssert(map[4] == nil)
        XCTAssert(map.assertIsOneToOne())

        // conflicting elements, choose existing
        map.insert((2, "three"), handlingConflictsWith: { conflict in
            guard case .conflictingElements(_) = conflict else {
                XCTFail(); return .chooseExisting
            }
            return .chooseExisting
        })
        XCTAssert(map[2] == "two")
        XCTAssert(map["three"] == 3)
        XCTAssert(map.assertIsOneToOne())
    }

    func testMapCodomain() {
        let intToWord: BijectiveMap = [
            1: "one",
            2: "two",
            3: "three"
        ]
        let wordsToReversed: BijectiveMap = [
            "two": "two".reversed(),
            "three": "three".reversed(),
            "four": "four".reversed()
        ]
        let composed = intToWord.mapCodomain(over: wordsToReversed)
        let expected: BijectiveMap = [
            2: "two".reversed(),
            3: "three".reversed()
        ]
        XCTAssert(composed == expected)
    }
}
