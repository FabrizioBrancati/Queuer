//
//  SchedulerTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2018 Fabrizio Brancati
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Dispatch
@testable import Queuer
import XCTest

internal class SchedulerTests: XCTestCase {
    internal static let allTests = [
        ("testInitWithoutHandler", testInitWithoutHandler),
        ("testInitWithHandler", testInitWithHandler)
    ]
    
    internal func testInitWithoutHandler() {
        let testExpectation = expectation(description: "Init Without Handler")
        
        var schedule = Scheduler(deadline: .now(), repeating: .seconds(1))
        schedule.setHandler {
            testExpectation.fulfill()
            schedule.timer.cancel()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
    
    internal func testInitWithHandler() {
        let testExpectation = expectation(description: "Init With Handler")
        
        let schedule = Scheduler(deadline: .now(), repeating: .seconds(1)) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            schedule.timer.cancel()
        }
    }
}
