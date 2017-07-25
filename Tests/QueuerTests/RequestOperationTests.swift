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

#if !os(Linux)

import XCTest
@testable import Queuer

class RequestOperationTests: XCTestCase {
    static let allTests = [
        ("testInit", testInit),
        ("testExecute", testExecute),
        ("testUnsupportedURL", testUnsupportedURL),
        ("testWrongURL", testWrongURL),
        ("testWithoutCompletionHandler", testWithoutCompletionHandler),
        ("testCancel", testCancel),
        ("testPauseAndResume", testPauseAndResume)
    ]
    
    let testAddress: String = "https://www.google.com"
    
    override func setUp() {
        super.setUp()
        
        RequestOperation.globalCachePolicy = .reloadIgnoringLocalCacheData
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        let queue = Queuer(name: "RequestOperationTestInit")
        let testExpectation = expectation(description: "Init")
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress, query: ["test": "test", "test2": "test2"], timeout: 30, method: .get, headers: ["test": "test", "test2": "test2"], body: Data()) { _, _, _, _ in
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        XCTAssertEqual(requestOperation.url?.absoluteString, self.testAddress)
        XCTAssertEqual(requestOperation.query, "?test=test&test2=test2")
        XCTAssertEqual(requestOperation.completeURL, URL(string: self.testAddress + "?test=test&test2=test2"))
        XCTAssertEqual(requestOperation.timeout, 30)
        XCTAssertEqual(requestOperation.method, .get)
        XCTAssertEqual(requestOperation.headers, ["test": "test", "test2": "test2"])
        XCTAssertEqual(requestOperation.body, Data())
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testExecute() {
        let queue = Queuer(name: "RequestOperationTestExecute")
        let testExpectation = expectation(description: "Execute")
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testUnsupportedURL() {
        let queue = Queuer(name: "RequestOperationTestUnsupportedURL")
        let testExpectation = expectation(description: "Unsupported URL")
        
        let requestOperation: RequestOperation = RequestOperation(url: "/path/to/something") { success, _, _, error in
            XCTAssertEqual(error?.localizedDescription, "unsupported URL")
            XCTAssertFalse(success)
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testWrongURL() {
        let queue = Queuer(name: "RequestOperationTestWrongURL")
        let testExpectation = expectation(description: "Wrong URL")
        
        let requestOperation: RequestOperation = RequestOperation(url: "👍") { success, _, _, error in
            XCTAssertEqual(error as? RequestOperation.RequestError, RequestOperation.RequestError.urlError)
            XCTAssertFalse(success)
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testWithoutCompletionHandler() {
        let queue = Queuer(name: "RequestOperationTestWithoutCompletionHandler")
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress)
        requestOperation.addToQueue(queue)
        
        XCTAssertEqual(queue.operations, [requestOperation])
        XCTAssertEqual(queue.operationCount, 1)
    }
    
    func testCancel() {
        let queue = Queuer(name: "RequestOperationTestCancel")
        let testExpectation = expectation(description: "Cancel")
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertEqual(error as? RequestOperation.RequestError, RequestOperation.RequestError.operationCancelled)
            XCTAssertFalse(success)
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        requestOperation.cancel()
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testPauseAndResume() {
        let queue = Queuer(name: "RequestOperationTestPauseAndResume")
        let testExpectation = expectation(description: "Pause and Resume")
        var order: [Int] = []
        
        let requestOperation1 = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            order.append(0)
        }
        let requestOperation2 = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            order.append(1)
        }
        queue.addChainedOperations([requestOperation1, requestOperation2]) {
            order.append(2)
        }
        
        queue.pause()
        testExpectation.fulfill()
        
        XCTAssertLessThanOrEqual(queue.operationCount, 3)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(queue.isExecuting)
            XCTAssertLessThanOrEqual(queue.operationCount, 3)
            XCTAssertNotEqual(order, [0, 1, 2])
            
            queue.resume()
            XCTAssertTrue(queue.isExecuting)
        })
    }
}

#endif
