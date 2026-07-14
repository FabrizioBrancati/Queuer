//
//  SharedQueuerTests.swift
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

import Foundation
import Queuer
import Testing

/// Every test touching `Queuer.shared` lives in this suite.
/// The suite is serialized, since Swift Testing runs tests in parallel
/// within the same process, and the shared queue is global state.
@Suite("Shared Queuer", .serialized)
struct SharedQueuerTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Add to the shared queuer")
    func addToSharedQueuer() async {
        let releaseOperation = DispatchSemaphore(value: 0)

        /// Hold the operation in the queue until the asserts have been made.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToSharedQueuer()

        #expect(Queuer.shared.operationCount >= 1)
        #expect(Queuer.shared.operations.contains(concurrentOperation))

        releaseOperation.signal()

        /// Leave the shared queue clean for the other tests.
        #expect(await waitUntil { Queuer.shared.operationCount == 0 })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operations run concurrently on the shared queuer")
    func concurrentOperationOnSharedQueuer() async {
        let testString = Protected("")
        let completed = Protected(false)
        let secondOperationDone = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            /// Deterministically finish after `concurrentOperation2`, without sleeping.
            _ = secondOperationDone.wait(timeout: .now() + .seconds(8))
            testString.mutate { $0 = "Tested1" }
            completed.mutate { $0 = true }
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested2" }
            secondOperationDone.signal()
        }
        Queuer.shared.maxConcurrentOperationCount = 2
        concurrentOperation2.addToSharedQueuer()
        concurrentOperation1.addToSharedQueuer()

        #expect(await waitUntil { completed.value })
        #expect(testString.value == "Tested1")

        /// Leave the shared queue in its default state for the other tests.
        Queuer.shared.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Serial shared queuer runs operations in order")
    func maxConcurrentOperationCountSetToOne() async {
        let testString = Protected("")
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested1" }
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested2" }

            /// On a serial queue `concurrentOperation2` is guaranteed to run last.
            completed.mutate { $0 = true }
        }
        Queuer.shared.maxConcurrentOperationCount = 1
        Queuer.shared.addOperation(concurrentOperation1)
        Queuer.shared.addOperation(concurrentOperation2)

        #expect(await waitUntil { completed.value })
        #expect(testString.value == "Tested2")

        /// Leave the shared queue in its default state for the other tests.
        Queuer.shared.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }
}
