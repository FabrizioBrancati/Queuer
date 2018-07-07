//
//  URLBuilderTests.swift
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

internal class URLBuilderTests: XCTestCase {
    internal static let allTests = [
        ("testWithoutParameters", testWithoutParameters),
        ("testWithSingleParameter", testBuildURLWithSingleParameter),
        ("testWithMultipleParameters", testWithMultipleParameters),
        ("testWithEmojiCharctersInParameters", testWithEmojiCharctersInParameters)
        //("testWithStrangeCharctersInParameters", testWithStrangeCharctersInParameters)
    ]
    
    internal func testWithoutParameters() {
        let query = URLBuilder.build(query: [:])
        
        XCTAssertEqual(query, "")
    }
    
    internal func testBuildURLWithSingleParameter() {
        let query = URLBuilder.build(query: ["test": "test"])
        
        XCTAssertEqual(query, "?test=test")
    }
    
    internal func testWithMultipleParameters() {
        let query = URLBuilder.build(query: ["test": "test", "test2": "test2"])
        
        XCTAssert(query == "?test=test&test2=test2" || query == "?test2=test2&test=test")
    }
    
    internal func testWithEmojiCharctersInParameters() {
        let query = URLBuilder.build(query: ["test": "test", "test👍": "test👍"])
        
        XCTAssert(query == "?test=test&test%F0%9F%91%8D=test%F0%9F%91%8D" || query == "?test%F0%9F%91%8D=test%F0%9F%91%8D&test=test")
    }
    
    /// Thanks to [Stack Overflow](https://stackoverflow.com/a/33558934/4032046 ).
    internal func testWithStrangeCharctersInParameters() {
        guard let string = String(bytes: [0xD8, 0x00] as [UInt8], encoding: String.Encoding.utf16BigEndian) else {
            XCTFail("`testWithStrangeCharctersInParameters` error")
            return
        }
        
        let query = URLBuilder.build(query: [string: "test", "test👍": string])
        XCTAssertEqual(query, "")
    }
}
