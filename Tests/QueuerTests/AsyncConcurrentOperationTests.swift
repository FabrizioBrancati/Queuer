//
//  AsyncConcurrentOperationTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2024 Fabrizio Brancati
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

import Queuer
import XCTest

final class AsyncConcurrentOperationTests: XCTestCase {
    func testAsyncChainedRetry() async {
        let queue = Queuer(name: "ConcurrentOperationTestChainedRetry")
        let testExpectation = expectation(description: "Chained Retry")
        let order = Order()

        let concurrentOperation1 = AsyncConcurrentOperation { operation in
            try? await Task.sleep(for: .seconds(1))
            await order.append(0)
            operation.success = false
        }
        let concurrentOperation2 = AsyncConcurrentOperation { operation in
            await order.append(1)
            operation.success = false
        }
        queue.addChainedAsyncOperations([concurrentOperation1, concurrentOperation2]) {
            await order.append(2)
            testExpectation.fulfill()
        }

        await fulfillment(of: [testExpectation], timeout: 10)
        let finalOrder = await order.order
        XCTAssertEqual(finalOrder, [0, 0, 0, 1, 1, 1, 2])
    }
}
