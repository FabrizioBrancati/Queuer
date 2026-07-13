//
//  SemaphoreTests.swift
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

import Queuer
import XCTest

final class SemaphoreTests: XCTestCase {
    func testWithSemaphore() {
        let semaphore = Semaphore()
        let queue = Queuer(name: "SemaphoreTestWithSemaphore")
        let testExpectation = expectation(description: "With Semaphore")
        let testString = Protected("")

        let concurrentOperation = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested" }
            semaphore.continue()
        }
        concurrentOperation.addToQueue(queue)

        /// Use a bounded wait so a failure doesn't hang the whole test run.
        XCTAssertEqual(semaphore.wait(.now() + .seconds(8)), .success)
        XCTAssertEqual(testString.value, "Tested")
        testExpectation.fulfill()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

    func testWithoutSemaphore() {
        let queue = Queuer(name: "SemaphoreTestWithoutSemaphore")
        let testExpectation = expectation(description: "Without Semaphore")
        let testString = Protected("")
        let releaseOperation = DispatchSemaphore(value: 0)

        let concurrentOperation = ConcurrentOperation { _ in
            /// Hold the operation until the initial assert has been made,
            /// instead of relying on it being slower than the main thread.
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested" }
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)

        XCTAssertEqual(testString.value, "")
        releaseOperation.signal()

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString.value, "Tested")
        }
    }
}
