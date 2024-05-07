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
        if CIHelper.isRunningOnCI() {
            let semaphore = Semaphore()
            let queue = Queuer(name: "SemaphoreTestWithSemaphore")
            let testExpectation = expectation(description: "With Semaphore")
            var testString = ""

            let concurrentOperation = ConcurrentOperation { _ in
                Thread.sleep(forTimeInterval: 2)
                testString = "Tested"
                semaphore.continue()
            }
            concurrentOperation.addToQueue(queue)

            semaphore.wait()
            XCTAssertEqual(testString, "Tested")
            testExpectation.fulfill()

            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error)
            }
        }
    }

    func testWithoutSemaphore() {
        if CIHelper.isRunningOnCI() {
            let queue = Queuer(name: "SemaphoreTestWithoutSemaphore")
            let testExpectation = expectation(description: "Without Semaphore")
            var testString = ""

            let concurrentOperation = ConcurrentOperation { _ in
                Thread.sleep(forTimeInterval: 2)
                testString = "Tested"
                testExpectation.fulfill()
            }
            concurrentOperation.addToQueue(queue)

            XCTAssertEqual(testString, "")

            waitForExpectations(timeout: 5) { error in
                XCTAssertNil(error)
                XCTAssertEqual(testString, "Tested")
            }
        }
    }
}
