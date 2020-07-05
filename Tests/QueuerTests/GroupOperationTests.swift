//
//  GroupOperationTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2020 Fabrizio Brancati
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

internal class GroupOperationTests: XCTestCase {
    internal func testGroupOperations() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupOperations")
        let queue = Queuer(name: "Group Operations")
        
        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    Thread.sleep(forTimeInterval: 1)
                    order.append("1")
                },
                ConcurrentOperation { _ in
                    order.append("2")
                }
            ]
        ) {
            order.append("3")
        }
        
        let groupOperation2 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    order.append("4")
                },
                ConcurrentOperation { _ in
                    Thread.sleep(forTimeInterval: 1)
                    order.append("5")
                }
            ]
        ) {
            order.append("6")
        }
        
        let groupOperation3 = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: 1)
            order.append("7")
        }
        
        queue.addChainedOperations([groupOperation1, groupOperation2, groupOperation3]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertTrue(groupOperation1.allOperationsSucceeded)
            XCTAssertNil(error)
            XCTAssertEqual(order, ["2", "1", "3", "4", "5", "6", "7"])
        }
    }
    
    internal func testGroupOperationsWithInnerChainedRetry() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupOperationsWithInnerChainedRetry")
        let queue = Queuer(name: "Group Operations Chained Retry")
        
        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { _ in
                    order.append("1")
                },
                ConcurrentOperation { operation in
                    Thread.sleep(forTimeInterval: 1)
                    order.append("2")
                    operation.success = false
                }
            ]
        )
        
        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }
        
        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 8) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1", "2", "2", "2", "3"])
        }
    }
    
    internal func testGroupOperationsWithCancelledInnerChainedRetry() {
        let queue = Queuer(name: "GroupOperationsWithCancelledInnerChainedRetry")
        let testExpectation = expectation(description: "Group Operations Cancelled Inner Chained Retry")
        var order: [String] = []
        
        let groupOperation1 = GroupOperation(
            [
                ConcurrentOperation { operation in
                    Thread.sleep(forTimeInterval: 1)
                    order.append("1")
                    operation.success = false
                },
                ConcurrentOperation { operation in
                    operation.cancel()
                    guard !operation.isCancelled else {
                        return
                    }
                    order.append("2")
                    operation.success = false
                }
            ]
        )
        
        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }
        
        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 6) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1", "1", "1", "3"])
        }
    }
    
    internal func testGroupOperationsWithInnerChainedManualRetry() {
        let queue = Queuer(name: "GroupOperationsWithInnerChainedManualRetry")
        let testExpectation = expectation(description: "Group Operations Inner Chained Manual Retry")
        var order: [String] = []
        
        let concurrentOperation1 = ConcurrentOperation { operation in
            order.append("1")
            operation.success = false
        }
        concurrentOperation1.manualRetry = true
        
        let concurrentOperation2 = ConcurrentOperation { operation in
            Thread.sleep(forTimeInterval: 1)
            order.append("2")
            operation.success = false
        }
        concurrentOperation2.manualRetry = true
        
        let groupOperation1 = GroupOperation([concurrentOperation1, concurrentOperation2])
        
        let groupOperation2 = ConcurrentOperation { _ in
            order.append("3")
        }
        
        queue.addChainedOperations([groupOperation1, groupOperation2]) {
            testExpectation.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            concurrentOperation1.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
            concurrentOperation2.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            concurrentOperation2.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(6)) {
            concurrentOperation1.retry()
        }
        
        waitForExpectations(timeout: 8) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1", "2", "1", "2", "2", "1", "3"])
        }
    }
}
