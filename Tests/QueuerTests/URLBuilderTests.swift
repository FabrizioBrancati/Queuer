//
//  URLBuilderTests.swift
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

class URLBuilderTests: XCTestCase {
    static let allTests = [
        ("testWithoutParameters", testWithoutParameters),
        ("testWithSingleParameter", testBuildURLWithSingleParameter),
        ("testWithMultipleParameters", testWithMultipleParameters),
        ("testWithStrangeCharctersInParameters", testWithStrangeCharctersInParameters)
    ]
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWithoutParameters() {
        let query = URLBuilder.build(query: [:])
        
        XCTAssertEqual(query, "")
    }
    
    func testBuildURLWithSingleParameter() {
        let query = URLBuilder.build(query: ["test": "test"])
        
        XCTAssertEqual(query, "?test=test")
    }
    
    func testWithMultipleParameters() {
        let query = URLBuilder.build(query: ["test": "test", "test2": "test2"])
        
        XCTAssertEqual(query, "?test=test&test2=test2")
    }
    
    func testWithStrangeCharctersInParameters() {
        let query = URLBuilder.build(query: ["test": "test", "test👎": "test👎"])
        
        XCTAssertEqual(query, "?test=test&test%F0%9F%91%8E=test%F0%9F%91%8E")
    }
}
