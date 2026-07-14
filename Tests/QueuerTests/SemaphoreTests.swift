//
//  SemaphoreTests.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2026 Fabrizio Brancati
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
import Foundation
import Queuer
import Testing

@Suite("Semaphore")
struct SemaphoreTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Wait is released by a continue call")
    func withSemaphore() async {
        let semaphore = Semaphore()
        let queue = Queuer(name: "SemaphoreTestWithSemaphore")
        let testString = Protected("")
        let waitResult = Protected<DispatchTimeoutResult?>(nil)

        let concurrentOperation = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested" }
            semaphore.continue()
        }
        concurrentOperation.addToQueue(queue)

        /// The blocking wait runs on a background thread,
        /// to keep the cooperative thread pool free.
        onBackgroundThread {
            waitResult.mutate { $0 = semaphore.wait(.now() + .seconds(8)) }
        }

        #expect(await waitUntil { waitResult.value != nil })
        #expect(waitResult.value == .success)
        #expect(testString.value == "Tested")
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operation runs only after being released")
    func withoutSemaphore() async {
        let queue = Queuer(name: "SemaphoreTestWithoutSemaphore")
        let testString = Protected("")
        let completed = Protected(false)
        let releaseOperation = DispatchSemaphore(value: 0)

        let concurrentOperation = ConcurrentOperation { _ in
            /// Hold the operation until the initial assert has been made,
            /// instead of relying on it being slower than the test.
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested" }
            completed.mutate { $0 = true }
        }
        concurrentOperation.addToQueue(queue)

        #expect(testString.value == "")
        releaseOperation.signal()

        #expect(await waitUntil { completed.value })
        #expect(testString.value == "Tested")
    }
}
