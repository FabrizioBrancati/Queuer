//
//  SynchronousOperationTests.swift
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

class SynchronousOperationTests: XCTestCase {
    static let allTests = [
        ("testSynchronousOperation", testSynchronousOperation),
        ("testSynchronousOperationOnSharedQueuer", testSynchronousOperationOnSharedQueuer),
        ("testCancel", testCancel)
    ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSynchronousOperation() {
        let queue = Queuer(name: "SynchronousOperationTestSynchronousOperation")
        let testExpectation = expectation(description: "Synchronous Operation")
        var testString = ""
        
        let synchronousOperation1 = SynchronousOperation {
            testString = "Tested1"
        }
        let synchronousOperation2 = SynchronousOperation {
            Thread.sleep(forTimeInterval: 2)
            testString = "Tested2"
            
            testExpectation.fulfill()
        }
        synchronousOperation1.addToQueue(queue)
        synchronousOperation2.addToQueue(queue)
        
        XCTAssertFalse(synchronousOperation1.isAsynchronous)
        XCTAssertFalse(synchronousOperation2.isAsynchronous)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString, "Tested2")
        })
    }
    
    func testSynchronousOperationOnSharedQueuer() {
        let testExpectation = expectation(description: "Synchronous Operation")
        var testString = ""
        
        let synchronousOperation1 = SynchronousOperation {
            testString = "Tested1"
        }
        let synchronousOperation2 = SynchronousOperation {
            Thread.sleep(forTimeInterval: 2)
            testString = "Tested2"
            
            testExpectation.fulfill()
        }
        synchronousOperation1.addToSharedQueuer()
        synchronousOperation2.addToSharedQueuer()
        
        XCTAssertFalse(synchronousOperation1.isAsynchronous)
        XCTAssertFalse(synchronousOperation2.isAsynchronous)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString, "Tested2")
        })
    }
    
    func testCancel() {
        let queue = Queuer(name: "SynchronousOperationTestCancel")
        let testExpectation = expectation(description: "Cancel")
        var testString = ""
        
        let cancelAllTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: cancelAllTime) {
            queue.cancelAll()
            Thread.sleep(forTimeInterval: 2)
        }
        
        let synchronousOperation1 = SynchronousOperation {
            testString = "Tested1"
            Thread.sleep(forTimeInterval: 4)
        }
        let synchronousOperation2 = SynchronousOperation {
            testString = "Tested2"
            
            testExpectation.fulfill()
        }
        synchronousOperation1.addToQueue(queue)
        synchronousOperation2.addToQueue(queue)
        
        XCTAssertFalse(synchronousOperation1.isAsynchronous)
        XCTAssertFalse(synchronousOperation2.isAsynchronous)
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString, "Tested1")
        })
    }
}
