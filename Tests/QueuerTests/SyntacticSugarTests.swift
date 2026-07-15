//
//  SyntacticSugarTests.swift
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

@Suite("SyntacticSugar")
struct SyntacticSugarTests {
    @Test("Fluent setters configure the operation")
    func concurrentOperationSugar() {
        let concurrentOperation = ConcurrentOperation()
            .name("SugarOperation")
            .queuePriority(.high)
            .qualityOfService(.utility)
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .retryDelay(1)
            .executionBlock { _ in }
            .onPause { _ in }
            .onResume { _ in }
            .onCancel { _ in }

        #expect(concurrentOperation.name == "SugarOperation")
        #expect(concurrentOperation.queuePriority == .high)
        #expect(concurrentOperation.qualityOfService == .utility)
        #expect(concurrentOperation.manualFinish)
        #expect(concurrentOperation.manualRetry)
        #expect(concurrentOperation.maximumRetries == 5)
        #expect(concurrentOperation.retryDelay == 1)
        #expect(concurrentOperation.executionBlock != nil)
        #expect(concurrentOperation.onPause != nil)
        #expect(concurrentOperation.onResume != nil)
        #expect(concurrentOperation.onCancel != nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Complex chain runs with the barrier in the middle")
    func complexCaseOfSyntacticSugar() async {
        let operations = Protected<[String]>([])
        let completed = Protected(false)

        let operation = ConcurrentOperation()
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { op in
                operations.append("Operation 1")
                op.finish()
            }

        let operation2 = ConcurrentOperation()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { _ in
                operations.append("Operation 2")
            }

        /// `.background` quality of service must be avoided here:
        /// loaded CI runners can defer background work for tens of seconds,
        /// making the test time out.
        Queuer(name: "SyntacticSugar")
            .maxConcurrentOperationCount(1)
            .qualityOfService(.userInitiated)
            .concurrent { _ in
                operations.append("Concurrent 1")
            }
            .add(
                ConcurrentOperation { _ in
                    operations.append("Add")
                }
            )
            .completion {
                operations.append("Step 1")
            }
            .chained(operation, operation2)
            .completion {
                operations.append("Step 2")
            }
            .concurrent { _ in
                operations.append("Concurrent 2")
            }
            .barrier {
                operations.append("Barrier")
            }
            .chained(
                ConcurrentOperation { _ in
                    operations.append("Chain 1")
                },
                ConcurrentOperation { _ in
                    operations.append("Chain 2")
                }
            )
            .completion {
                operations.append("Step 3")
            }
            .completion {
                operations.append("Step 4")
            }
            .group(
                ConcurrentOperation { _ in
                    operations.append("Group 1")
                },
                ConcurrentOperation { _ in
                    operations.append("Group 2")
                }
            )
            .syncWait(0.5)
            .completion {
                operations.append("Finished")
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })

        let order = operations.value
        #expect(order.count == 15)
        #expect(
            Set(order) == [
                "Concurrent 1", "Add", "Step 1", "Operation 1", "Operation 2", "Step 2", "Concurrent 2",
                "Barrier",
                "Chain 1", "Chain 2", "Step 3", "Step 4", "Group 1", "Group 2", "Finished"
            ]
        )

        /// The barrier must run after everything added before it,
        /// and before everything added after it.
        let beforeBarrier = ["Concurrent 1", "Add", "Step 1", "Operation 1", "Operation 2", "Step 2", "Concurrent 2"]
        let afterBarrier = ["Chain 1", "Chain 2", "Step 3", "Step 4", "Group 1", "Group 2", "Finished"]
        if let barrierIndex = order.firstIndex(of: "Barrier") {
            for element in beforeBarrier {
                if let index = order.firstIndex(of: element) {
                    #expect(index < barrierIndex, "\(element) should run before the barrier")
                }
            }
            for element in afterBarrier {
                if let index = order.firstIndex(of: element) {
                    #expect(index > barrierIndex, "\(element) should run after the barrier")
                }
            }
        }

        /// Chained operations and their completions must preserve their order.
        if let chain1 = order.firstIndex(of: "Chain 1"), let chain2 = order.firstIndex(of: "Chain 2") {
            #expect(chain1 < chain2)
        }
        #expect(order.last == "Finished")
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    @Test("Async wait delays the queue without blocking a thread")
    func asyncWait() async {
        let completed = Protected(false)
        let start = Date()

        Queuer(name: "SyntacticSugarTestAsyncWait")
            .asyncWait(.milliseconds(100))
            .completion {
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })
        /// The wait must last at least the requested time.
        /// A lenient lower bound avoids failures from clock differences.
        #expect(Date().timeIntervalSince(start) >= 0.05)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Sync wait delays the queue")
    func syncWait() async {
        let completed = Protected(false)
        let start = Date()

        Queuer(name: "SyntacticSugarTestSyncWait")
            .syncWait(0.1)
            .completion {
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })
        #expect(Date().timeIntervalSince(start) >= 0.05)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Fluent setters configure the async operation")
    func asyncConcurrentOperationSugar() {
        let concurrentOperation = AsyncConcurrentOperation()
            .name("AsyncSugarOperation")
            .queuePriority(.high)
            .qualityOfService(.utility)
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .retryDelay(1)
            .executionBlock { _ in }
            .onPause { _ in }
            .onResume { _ in }
            .onCancel { _ in }

        #expect(concurrentOperation.name == "AsyncSugarOperation")
        #expect(concurrentOperation.queuePriority == .high)
        #expect(concurrentOperation.qualityOfService == .utility)
        #expect(concurrentOperation.manualFinish)
        #expect(concurrentOperation.manualRetry)
        #expect(concurrentOperation.maximumRetries == 5)
        #expect(concurrentOperation.retryDelay == 1)
        #expect(concurrentOperation.executionBlock != nil)
        #expect(concurrentOperation.onPause != nil)
        #expect(concurrentOperation.onResume != nil)
        #expect(concurrentOperation.onCancel != nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Async concurrent blocks and async completion run in order")
    func asyncConcurrentAndAsyncCompletion() async {
        let order = Protected<[String]>([])
        let completed = Protected(false)

        Queuer(name: "SyntacticSugarTestAsyncConcurrent")
            .maxConcurrentOperationCount(1)
            .asyncConcurrent { _ in
                order.append("First")
            }
            .asyncConcurrent(retries: 2) { operation in
                order.append("Retry")
                operation.success = false
            }
            .asyncCompletion {
                order.append("Finished")
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })
        /// "Retry" fails with 2 maximum retries.
        #expect(order.value == ["First", "Retry", "Retry", "Finished"])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained blocks and retryable concurrent blocks run in order")
    func chainedBlocksAndConcurrentRetries() async {
        let order = Protected<[String]>([])
        let completed = Protected(false)

        Queuer(name: "SyntacticSugarTestChainedBlocks")
            .maxConcurrentOperationCount(1)
            .chained(
                { _ in
                    order.append("First")
                },
                { operation in
                    order.append("Second")
                    operation.success = false
                }
            )
            .concurrent(retries: 2) { operation in
                order.append("Retry")
                operation.success = false
            }
            .completion {
                order.append("Finished")
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })
        /// "Second" fails with the default 3 maximum retries,
        /// "Retry" fails with 2 maximum retries.
        #expect(order.value == ["First", "Second", "Second", "Second", "Retry", "Retry", "Finished"])
    }
}
