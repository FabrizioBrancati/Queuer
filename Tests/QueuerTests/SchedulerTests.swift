//
//  SchedulerTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2024 Fabrizio Brancati
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
import Queuer
import XCTest

final class SchedulerTests: XCTestCase {
    func testInitWithoutHandler() {
        let testExpectation = expectation(description: "Init Without Handler")
        let order = Protected<[Int]>([])

        var schedule = Scheduler(deadline: .now(), repeating: .milliseconds(100))
        schedule.setHandler {
            /// Count the ticks instead of measuring time.
            /// Cancel on the fourth one, the timer's queue is serial so no other tick can race this.
            let count = order.mutate { value -> Int in
                value.append(0)
                return value.count
            }

            if count == 4 {
                schedule.timer.cancel()
                testExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0, 0, 0, 0])
        }
    }

    func testInitWithHandler() {
        let testExpectation = expectation(description: "Init With Handler")
        let order = Protected<[Int]>([])

        let schedule = Scheduler(deadline: .now(), repeating: .never) {
            order.append(0)

            /// A `.never` repeating timer must only fire once.
            /// Give it a short, bounded amount of time to (wrongly) fire again before asserting.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(300)) {
                testExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0])
            schedule.timer.cancel()
        }
    }

    func testCancel() {
        let testExpectation = expectation(description: "Cancel")
        let order = Protected<[Int]>([])

        var schedule = Scheduler(deadline: .now(), repeating: .milliseconds(100))
        schedule.setHandler {
            order.append(0)
            schedule.timer.cancel()

            /// The timer has been canceled on the first tick.
            /// Give it a short, bounded amount of time to (wrongly) fire again before asserting.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(300)) {
                testExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order.value, [0])
        }
    }
}
