//
//  SmaphoreTests.swift
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

class SemaphoreTests: XCTestCase {
    static let allTests = [
        ("testWithSemaphore", testWithSemaphore),
        ("testWithoutSemaphore", testWithoutSemaphore)
    ]
    
    let testAddress: String = "https://www.google.com"
    
    override func setUp() {
        super.setUp()
        
        RequestOperation.globalCachePolicy = .reloadIgnoringLocalCacheData
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWithSemaphore() {
        let semaphore = Semaphore()
        let queue = Queuer(name: "SemaphoreTestWithSemaphore")
        let testExpectation = expectation(description: "With Semaphore")
        var testString = ""
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            testString = "Tested"
            sleep(2)
            semaphore.continue()
        }
        requestOperation.addToQueue(queue)
        
        semaphore.wait()
        XCTAssertEqual(testString, "Tested")
        testExpectation.fulfill()
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testWithoutSemaphore() {
        let queue = Queuer(name: "SemaphoreTestWithoutSemaphore")
        let testExpectation = expectation(description: "Without Semaphore")
        var testString = ""
        
        let requestOperation: RequestOperation = RequestOperation(url: self.testAddress) { success, _, _, error in
            XCTAssertNil(error)
            XCTAssertTrue(success)
            testString = "Tested"
            sleep(2)
            testExpectation.fulfill()
        }
        requestOperation.addToQueue(queue)
        
        XCTAssertEqual(testString, "")
        
        waitForExpectations(timeout: 5, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(testString, "Tested")
        })
    }
}
