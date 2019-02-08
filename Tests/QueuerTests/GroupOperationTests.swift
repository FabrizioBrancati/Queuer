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
    func testGroupedOperations() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupedOperations")
        let queue = Queuer(name: "Grouped Operations")
        
        let operation1 = GroupOperation([
            ConcurrentOperation() { _ in
                Thread.sleep(forTimeInterval: 0.2)
                order.append("1_A")
            },
            ConcurrentOperation() { _ in
                order.append("1_B")
            }
        ]) { _ in
            order.append("1_ended")
        }
        
        let operation2 = GroupOperation([
            ConcurrentOperation() { _ in
                order.append("2_A")
            },
            ConcurrentOperation() { _ in
                Thread.sleep(forTimeInterval: 0.2)
                order.append("2_B")
            }
        ]) { _ in
            order.append("2_ended")
        }
        
        let operation3 = ConcurrentOperation() { _ in
            order.append("3")
        }
        
        queue.addChainedOperations([operation1, operation2, operation3]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1_B", "1_A", "1_ended", "2_A", "2_B", "2_ended", "3"])
        }
    }
    
    func testGroupedOperationsWithInnerChainedRetry() {
        var order: [String] = []
        let testExpectation = expectation(description: "GroupedOperationsWithInnerChainedRetry")
        let queue = Queuer(name: "Grouped Operations Chained Retry")
        
        let operation1 = GroupOperation([
            ConcurrentOperation() { _ in
                order.append("1_A")
            },
            ConcurrentOperation() { operation in
                Thread.sleep(forTimeInterval: 0.2)
                order.append("1_B")
                operation.success = false
            }
            ])
        
        let operation2 = ConcurrentOperation() { _ in
            order.append("2")
        }
        
        queue.addChainedOperations([operation1, operation2]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1_A", "1_B", "1_B", "1_B", "2"])
        }
    }
    
    func testGroupedOperationsWithCancelledInnerChainedRetry() {
        let queue = Queuer(name: "GroupedOperationsWithCancelledInnerChainedRetry")
        let testExpectation = expectation(description: "Grouped Operations Cancelled Inner Chained Retry")
        var order: [String] = []
        
        let operation1 = GroupOperation([
            ConcurrentOperation() { operation in
                Thread.sleep(forTimeInterval: 0.2)
                order.append("1_A")
                operation.success = false
            },
            ConcurrentOperation() { operation in
                operation.cancel()
                guard !operation.isCancelled else {
                    return
                }
                order.append("1_B")
                operation.success = false
            }
            ])
        
        let operation2 = ConcurrentOperation() { _ in
            order.append("2")
        }
        
        queue.addChainedOperations([operation1, operation2]) {
            testExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1_A", "1_A", "1_A", "2"])
        }
    }
    
    func testGroupedOperationsWithInnerChainedManualRetry() {
        let queue = Queuer(name: "GroupedOperationsWithInnerChainedManualRetry")
        let testExpectation = expectation(description: "Grouped Operations Inner Chained Manual Retry")
        var order: [String] = []
        
        let operation1A = ConcurrentOperation() { operation in
            order.append("1_A")
            operation.success = false
        }
        operation1A.manualRetry = true
        
        let operation1B = ConcurrentOperation() { operation in
            Thread.sleep(forTimeInterval: 0.2)
            order.append("1_B")
            operation.success = false
        }
        operation1B.manualRetry = true
        
        let operation1 = GroupOperation([operation1A, operation1B])
        
        let operation2 = ConcurrentOperation() { _ in
            order.append("2")
        }
        
        queue.addChainedOperations([operation1, operation2]) {
            testExpectation.fulfill()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
            operation1A.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            operation1B.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1200)) {
            operation1B.retry()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1400)) {
            operation1A.retry()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            XCTAssertEqual(order, ["1_A", "1_B", "1_A", "1_B", "1_B", "1_A", "2"])
        }
    }
}
