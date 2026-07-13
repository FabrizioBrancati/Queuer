//
//  SyntacticSugarTests.swift
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

final class SyntacticSugarTests: XCTestCase {
    func testConcurrentOperationSugar() {
        let concurrentOperation = ConcurrentOperation()
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { _ in }

        XCTAssertTrue(concurrentOperation.manualFinish)
        XCTAssertTrue(concurrentOperation.manualRetry)
        XCTAssertEqual(concurrentOperation.maximumRetries, 5)
        XCTAssertNotNil(concurrentOperation.executionBlock)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testComplexCaseOfSyntacticSugar() {
        let testExpectation = expectation(description: "Complex Case Of Syntactic Sugar")

        let operations = Protected<[String]>([])

        let operation = ConcurrentOperation()
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { op in
                operations.append("Operation 1")
                op.finish()
            }

        let operation2 = ConcurrentOperation()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { _ in
                operations.append("Operation 2")
            }

        Queuer(name: "SyntacticSugar")
            .maxConcurrentOperationCount(1)
            .qualityOfService(.background)
            .concurrent { _ in
                operations.append("Concurrent 1")
            }
            .add(
                ConcurrentOperation { _ in
                    operations.append("Add")
                }
            )
            .completion {
                operations.append("Step 1")
            }
            .chained(operation, operation2)
            .completion {
                operations.append("Step 2")
            }
            .concurrent { _ in
                operations.append("Concurrent 2")
            }
            .barrier {
                operations.append("Barrier")
            }
            .chained(
                ConcurrentOperation { _ in
                    operations.append("Chain 1")
                },
                ConcurrentOperation { _ in
                    operations.append("Chain 2")
                }
            )
            .completion {
                operations.append("Step 3")
            }
            .completion {
                operations.append("Step 4")
            }
            .group(
                ConcurrentOperation { _ in
                    operations.append("Group 1")
                },
                ConcurrentOperation { _ in
                    operations.append("Group 2")
                }
            )
            .syncWait(0.5)
            .completion {
                operations.append("Finished")
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)

            let order = operations.value
            XCTAssertEqual(order.count, 15)
            XCTAssertEqual(
                Set(order),
                [
                    "Concurrent 1", "Add", "Step 1", "Operation 1", "Operation 2", "Step 2", "Concurrent 2",
                    "Barrier",
                    "Chain 1", "Chain 2", "Step 3", "Step 4", "Group 1", "Group 2", "Finished"
                ]
            )

            /// The barrier must run after everything added before it,
            /// and before everything added after it.
            let beforeBarrier = ["Concurrent 1", "Add", "Step 1", "Operation 1", "Operation 2", "Step 2", "Concurrent 2"]
            let afterBarrier = ["Chain 1", "Chain 2", "Step 3", "Step 4", "Group 1", "Group 2", "Finished"]
            if let barrierIndex = order.firstIndex(of: "Barrier") {
                for element in beforeBarrier {
                    if let index = order.firstIndex(of: element) {
                        XCTAssertLessThan(index, barrierIndex, "\(element) should run before the barrier")
                    }
                }
                for element in afterBarrier {
                    if let index = order.firstIndex(of: element) {
                        XCTAssertGreaterThan(index, barrierIndex, "\(element) should run after the barrier")
                    }
                }
            }

            /// Chained operations and their completions must preserve their order.
            if let chain1 = order.firstIndex(of: "Chain 1"), let chain2 = order.firstIndex(of: "Chain 2") {
                XCTAssertLessThan(chain1, chain2)
            }
            XCTAssertEqual(order.last, "Finished")
        }
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    func testAsyncWait() {
        let testExpectation = expectation(description: "Async Wait")
        let start = Date()

        Queuer(name: "SyntacticSugarTestAsyncWait")
            .asyncWait(.milliseconds(100))
            .completion {
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            /// The wait must last at least the requested time.
            /// A lenient lower bound avoids failures from clock differences.
            XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.05)
        }
    }

    func testSyncWait() {
        let testExpectation = expectation(description: "Sync Wait")
        let start = Date()

        Queuer(name: "SyntacticSugarTestSyncWait")
            .syncWait(0.1)
            .completion {
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
            XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.05)
        }
    }
}
