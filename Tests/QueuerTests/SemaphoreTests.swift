//
//  SemaphoreTests.swift
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
import Testing

@Suite struct SemaphoreTests {
    @Test func testWithSemaphore() async {
        if CIHelper.isNotCI() {
            await confirmation("With Semaphore") { confirmation in
                let semaphore = Semaphore()
                let queue = Queuer(name: "SemaphoreTestWithSemaphore")
                var testString = ""

                let concurrentOperation = ConcurrentOperation { _ in
                    // Thread.sleep(forTimeInterval: 2)
                    testString = "Tested"
                    semaphore.continue()
                }
                concurrentOperation.addToQueue(queue)

                semaphore.wait()
                #expect(testString == "Tested")
                confirmation()
            }
        }
    }

    @Test func testWithoutSemaphore() async throws {
        if CIHelper.isNotCI() {
            try await confirmation("Without Semaphore") { confirmation in
                let queue = Queuer(name: "SemaphoreTestWithoutSemaphore")
                var testString = ""

                let concurrentOperation = ConcurrentOperation { _ in
                    // Thread.sleep(forTimeInterval: 2)
                    testString = "Tested"
                    confirmation()
                }
                concurrentOperation.addToQueue(queue)

                #expect(testString == "")

                try await Task.sleep(for: .seconds(2))
                #expect(testString == "Tested")
            }
        }
    }
}
