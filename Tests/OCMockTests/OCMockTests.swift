//
//  OCMockTests.swift
//  
//
//  Created by Mayur Sharma on 22/11/19.
//

import XCTest
@testable import OCMock

final class OCMockTests: XCTestCase {
    func testExample() {
        XCTAssertNotNil(OCMockObject(), "OCMock module error!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

