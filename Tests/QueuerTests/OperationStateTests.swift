//
//  OperationStateTests.swift
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

import Dispatch
@testable import Queuer
import XCTest

internal class OperationStateTests: XCTestCase {
    internal func testInitOperationState() {
        let operationState = OperationState(name: "Test", progress: 50, dependencies: ["Test2"])
        
        XCTAssertEqual(operationState.name, "Test")
        XCTAssertEqual(operationState.progress, 50)
        XCTAssertEqual(operationState.dependencies, ["Test2"])
    }
    
    internal func testCustomDescription() {
        let operationState = OperationState(name: "Test", progress: 50, dependencies: ["Test2"])
        
        XCTAssertEqual(operationState.description, """
        Operation Name: Test
        Operation Progress: 50
        Operation Dependencies: ["Test2"]
        """)
    }
    
    internal func testEncodeDecode() {
        var operationState = OperationState(name: "Test", progress: 50, dependencies: ["Test2"])
        
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail()
            return
        }
        
        let url = documents.appendingPathComponent("Test.plist")
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(operationState)
            try data.write(to: url)
        } catch {
            XCTFail()
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            operationState = try decoder.decode(OperationState.self, from: data)
            
            XCTAssertEqual(operationState.name, "Test")
            XCTAssertEqual(operationState.progress, 50)
            XCTAssertEqual(operationState.dependencies, ["Test2"])
        } catch {
            XCTFail()
        }
    }
}
