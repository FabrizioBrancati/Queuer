//
//  GroupOperationTests.swift
//  Queuer
//
//  Created by Jerome Pasquier on 06/02/2019.
//  Copyright © 2019 Fabrizio Brancati. All rights reserved.
//

import XCTest

@testable import Queuer
import XCTest

internal class GroupOperationTests: XCTestCase {
    func testGroupOperations() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupOperations")
        let queue = Queuer(name: "Group Operations")
        
        let groupOperation1 = GroupOperation([
            ConcurrentOperation() { _ in
                Thread.sleep(forTimeInterval: 1)
                order.append("1")
            },
            ConcurrentOperation() { _ in
                order.append("2")
            }
        ]) {
            order.append("3")
        }
        
        let groupOperation2 = GroupOperation([
            ConcurrentOperation() { _ in
                order.append("4")
            },
            ConcurrentOperation() { _ in
                Thread.sleep(forTimeInterval: 1)
                order.append("5")
            }
        ]) {
            order.append("6")
        }
        
        let groupOperation3 = ConcurrentOperation() { _ in
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
    
    func testGroupOperationsWithInnerChainedRetry() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupOperationsWithInnerChainedRetry")
        let queue = Queuer(name: "Group Operations Chained Retry")
        
        let groupOperation1 = GroupOperation([
            ConcurrentOperation() { _ in
                order.append("1")
            },
            ConcurrentOperation() { operation in
                Thread.sleep(forTimeInterval: 1)
                order.append("2")
                operation.success = false
            }
            ])
        
        let groupOperation2 = ConcurrentOperation() { _ in
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
    
    func testGroupOperationsWithCancelledInnerChainedRetry() {
        let queue = Queuer(name: "GroupOperationsWithCancelledInnerChainedRetry")
        let testExpectation = expectation(description: "Group Operations Cancelled Inner Chained Retry")
        var order: [String] = []
        
        let groupOperation1 = GroupOperation([
            ConcurrentOperation() { operation in
                Thread.sleep(forTimeInterval: 1)
                order.append("1")
                operation.success = false
            },
            ConcurrentOperation() { operation in
                operation.cancel()
                guard !operation.isCancelled else {
                    return
                }
                order.append("2")
                operation.success = false
            }
        ])
        
        let groupOperation2 = ConcurrentOperation() { _ in
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
    
    func testGroupOperationsWithInnerChainedManualRetry() {
        let queue = Queuer(name: "GroupOperationsWithInnerChainedManualRetry")
        let testExpectation = expectation(description: "Group Operations Inner Chained Manual Retry")
        var order: [String] = []
        
        let concurrentOperation1 = ConcurrentOperation() { operation in
            order.append("1")
            operation.success = false
        }
        concurrentOperation1.manualRetry = true
        
        let concurrentOperation2 = ConcurrentOperation() { operation in
            Thread.sleep(forTimeInterval: 1)
            order.append("2")
            operation.success = false
        }
        concurrentOperation2.manualRetry = true
        
        let groupOperation1 = GroupOperation([concurrentOperation1, concurrentOperation2])
        
        let groupOperation2 = ConcurrentOperation() { _ in
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
