//
//  ConcurrentOperationTests.swift
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

@testable import Queuer
import XCTest

internal class ConcurrentOperationTests: XCTestCase {
    internal static let allTests = [
        ("testInitWithExecutionBlock", testInitWithExecutionBlock),
        ("testIsAsynchronous", testIsAsynchronous),
        ("testAddToSharedQueuer", testAddToSharedQueuer),
        ("testAddToQueue", testAddToQueue)
    ]
    
    internal func testInitWithExecutionBlock() {
        let queue = Queuer(name: "ConcurrentOperationTestInitWithExecutionBlock")
        
        let testExpectation = expectation(description: "Init With Execution Block")
        
        let concurrentOperation = ConcurrentOperation { _ in
            testExpectation.fulfill()
        }
        concurrentOperation.addToQueue(queue)
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    internal func testIsAsynchronous() {
        let concurrentOperation = ConcurrentOperation()
        
        XCTAssertTrue(concurrentOperation.isAsynchronous)
    }
    
    internal func testAddToSharedQueuer() {
        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToSharedQueuer()
        
        XCTAssertEqual(Queuer.shared.operationCount, 1)
        XCTAssertEqual(Queuer.shared.operations, [concurrentOperation])
    }
    
    internal func testAddToQueue() {
        let queue = Queuer(name: "ConcurrentOperationTestAddToQueuer")
        
        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToQueue(queue)
        
        XCTAssertEqual(queue.operationCount, 1)
        XCTAssertEqual(queue.operations, [concurrentOperation])
    }
}
