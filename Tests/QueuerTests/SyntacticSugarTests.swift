//
//  SyntaxSugarTests.swift
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

final class SyntaxSugarTests: XCTestCase {
    func testComplexCaseOfSyntaxSugar() {
        let testExpectation = expectation(description: "Complex Case Of Syntax Sugar")

        var operations: [String] = []

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

        Queuer(name: "Queue")
            .maxConcurrentOperationCount(1)
            .waitUntilAllOperationsAreFinished()
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
//            .chained(.concurrent {}, operation2)
            .concurrent { _ in
                operations.append("Concurrent 2")
            }
//            .asyncWait(.seconds(1))
            .chained(
                ConcurrentOperation { _ in
                    operations.append("Chain 1")
                },
                ConcurrentOperation { _ in
                    operations.append("Chain 2")
                }
            )
//         here you should have the value from the previous operations
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
            .syncWait(1)
            .completion {
                operations.append("Finished")
                testExpectation.fulfill()
            }

        waitForExpectations(timeout: 5) { error in
            XCTAssertEqual(operations.count, 14)
            XCTAssertNil(error)
        }
    }
}
