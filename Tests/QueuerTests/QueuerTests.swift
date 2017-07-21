//
//  QueuerTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 Fabrizio Brancati
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

import XCTest
@testable import Queuer

class QueuerTests: XCTestCase {
    let queuer: Queuer = Queuer.shared
    let testingAddress: String = "https://www.google.com"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSingleOperation() {
        queuer.maxConcurrentOperationCount = 1
        
        let testExpectation = expectation(description: "Single Operation")
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testingAddress, query: ["test": "test", "test 2": "test 2"]) { success, _, _, error in
            if error == nil && success {
                XCTAssertTrue(true)
            } else {
                XCTFail()
            }
            
            testExpectation.fulfill()
        }
        
        requestOperation.addToQueuer()
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error, "Error on RequestOperation.")
        })
    }
    
    func testChainedOperations() {
        let testExpectation = expectation(description: "Chained Operations")
        var order: [Int] = []
        
        let requestOperation1: RequestOperation = RequestOperation(url: self.testingAddress) { success, _, _, error in
            if error == nil && success {
                order.append(0)
            } else {
                XCTFail()
            }
        }
        let requestOperation2: RequestOperation = RequestOperation(url: self.testingAddress) { success, _, _, error in
            if error == nil && success {
                order.append(1)
            } else {
                XCTFail()
            }
        }
        
        self.queuer.addChainedOperations([requestOperation1, requestOperation2]) {
            order.append(2)
            testExpectation.fulfill()
        }
        
        XCTAssertEqual(self.queuer.operationCount, 3)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error, "Error on RequestOperation.")
            XCTAssertEqual(order, [0, 1, 2])
        })
    }
    
    func testCancelAllOperations() {
        let testExpectation = expectation(description: "Cancel Single Operation")
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testingAddress) { success, _, _, error in
            if error == nil && success {
                XCTFail()
            } else {
                XCTAssertTrue(true)
            }
            
            testExpectation.fulfill()
        }
        
        self.queuer.addOperation(requestOperation)
        
        self.queuer.cancelAll()
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error, "Error on RequestOperation.")
        })
    }
}
