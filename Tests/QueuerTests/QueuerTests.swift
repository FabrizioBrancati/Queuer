//
//  QueuerTests.swift
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

@Suite("Queuer")
struct QueuerTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operation count reflects the queue state")
    func operationCount() async {
        let queue = Queuer(name: "QueuerTestOperationCount")
        let releaseOperation = DispatchSemaphore(value: 0)

        #expect(queue.operationCount == 0)

        /// Keep the operation alive until the count has been verified.
        /// `DispatchSemaphore.wait(timeout:)` cannot be called from this
        /// asynchronous context, so the count is polled instead.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { queue.operationCount == 1 })
        releaseOperation.signal()

        /// The operation needs some time to leave the queue after its block returns,
        /// so poll the count instead of asserting right away.
        #expect(await waitUntil { queue.operationCount == 0 })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operations list reflects the queue state")
    func operations() async {
        let queue = Queuer(name: "QueuerTestOperations")
        let releaseOperation = DispatchSemaphore(value: 0)

        /// Keep the operation alive until the asserts have been made.
        /// `DispatchSemaphore.wait(timeout:)` cannot be called from this
        /// asynchronous context, so the operations list is polled instead.
        let concurrentOperation = ConcurrentOperation { _ in
            _ = releaseOperation.wait(timeout: .now() + .seconds(8))
        }
        queue.addOperation(concurrentOperation)

        #expect(await waitUntil { queue.operations.contains(concurrentOperation) })
        releaseOperation.signal()

        #expect(await waitUntil { !queue.operations.contains(concurrentOperation) })
    }

    @Test("Max concurrent operation count is configurable")
    func maxConcurrentOperationCount() {
        let queue = Queuer(name: "QueuerTestMaxConcurrentOperationCount")

        queue.maxConcurrentOperationCount = 10

        #expect(queue.maxConcurrentOperationCount == 10)
    }

    @Test("Quality of service is configurable")
    func qualityOfService() {
        let queue = Queuer(name: "QueuerTestQualityOfService")

        queue.qualityOfService = .background

        #expect(queue.qualityOfService == .background)
    }

    @Test("Init with name and max concurrent operation count")
    func initWithNameMaxConcurrentOperationCount() {
        let queueName = "TestInitWithNameMaxConcurrentOperationCount"
        let queue = Queuer(name: queueName, maxConcurrentOperationCount: 10)

        #expect(queue.queue.name == queueName)
        #expect(queue.queue.maxConcurrentOperationCount == 10)
    }

    @Test("Init with name, max concurrent operation count, and quality of service")
    func initWithNameMaxConcurrentOperationCountQualityOfService() {
        let queueName = "TestInitWithNameMaxConcurrentOperationCountQualityOfService"
        let queue = Queuer(name: queueName, maxConcurrentOperationCount: 10, qualityOfService: .background)

        #expect(queue.queue.name == queueName)
        #expect(queue.queue.maxConcurrentOperationCount == 10)
        #expect(queue.queue.qualityOfService == .background)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Add an operation block")
    func addOperationBlock() async {
        let queue = Queuer(name: "QueuerTestAddOperationBlock")
        let countDuringExecution = Protected(0)

        queue.addOperation {
            countDuringExecution.mutate { $0 = queue.operationCount }
        }

        #expect(await waitUntil { queue.operationCount == 0 })
        #expect(countDuringExecution.value == 1)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Add an operation")
    func addOperation() async {
        let queue = Queuer(name: "QueuerTestAddOperation")
        let countDuringExecution = Protected(0)

        let concurrentOperation = ConcurrentOperation { _ in
            countDuringExecution.mutate { $0 = queue.operationCount }
        }
        queue.addOperation(concurrentOperation)

        #expect(await waitUntil { queue.operationCount == 0 })
        #expect(countDuringExecution.value == 1)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Add multiple operations")
    func addOperations() async {
        let queue = Queuer(name: "QueuerTestAddOperations")
        let check = Protected(0)
        let releaseOperations = DispatchSemaphore(value: 0)

        let concurrentOperation1 = ConcurrentOperation { _ in
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
            check.mutate { $0 += 1 }
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            _ = releaseOperations.wait(timeout: .now() + .seconds(8))
            check.mutate { $0 += 1 }
        }
        queue.addOperation(concurrentOperation1)
        #expect(queue.operationCount == 1)

        queue.addOperation(concurrentOperation2)
        #expect(queue.operationCount == 2)

        releaseOperations.signal()
        releaseOperations.signal()

        #expect(await waitUntil { queue.operationCount == 0 && check.value == 2 })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations run in order")
    func addChainedOperations() async {
        let queue = Queuer(name: "QueuerTestAddChainedOperations")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations from a list run in order")
    func addChainedOperationsList() async {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsList")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations(concurrentOperation1, concurrentOperation2) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Empty chained operations execute the completion")
    func addChainedOperationsEmpty() async {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsEmpty")
        let completed = Protected(false)

        queue.addChainedOperations([]) {
            completed.mutate { $0 = true }
        }

        /// The completion handler runs as an operation itself,
        /// so wait for the queue to be empty before asserting.
        #expect(await waitUntil { completed.value && queue.operationCount == 0 })
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations without completion run in order")
    func addChainedOperationsWithoutCompletion() async {
        let queue = Queuer(name: "QueuerTestAddChainedOperationsWithoutCompletion")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2])

        #expect(await waitUntil { queue.operationCount == 0 && order.count == 2 })
        #expect(order.value == [0, 1])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceling a paused queue drops its operations")
    func cancel() async {
        let queue = Queuer(name: "QueuerTestCancel")
        let order = Protected<[Int]>([])

        /// Pause the queue so that no operation can start before `cancel()` is called.
        queue.pause()

        /// The operations are intentionally not chained: on Linux, canceling
        /// dependency-linked operations can crash inside corelibs-foundation's
        /// KVO handling when dependents finish before their prerequisites.
        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addOperation(concurrentOperation1)
        queue.addOperation(concurrentOperation2)

        queue.cancel()
        queue.resume()

        #expect(await waitUntil { queue.operationCount == 0 })
        #expect(order.value == [])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Pause and resume the queue")
    func pauseAndResume() async {
        let queue = Queuer(name: "QueuerTestPauseAndResume")
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        /// Pause the queue before adding operations so that none of them can start.
        queue.pause()
        #expect(queue.isExecuting == false)

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
            completed.mutate { $0 = true }
        }

        #expect(queue.operationCount == 3)
        #expect(order.value == [])

        queue.resume()
        #expect(queue.isExecuting)

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 1, 2])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Wait until all operations are finished")
    func waitUntilAllOperationsAreFinished() async {
        let queue = Queuer(name: "QueuerTestWaitUntilAllOperationsAreFinished")
        let order = Protected<[Int]>([])

        let concurrentOperation1 = ConcurrentOperation { _ in
            order.append(0)
        }
        let concurrentOperation2 = ConcurrentOperation { _ in
            order.append(1)
        }
        queue.addChainedOperations([concurrentOperation1, concurrentOperation2]) {
            order.append(2)
        }

        /// The operations are instantaneous, so the wait blocks this thread only briefly.
        queue.waitUntilAllOperationsAreFinished()

        #expect(order.value == [0, 1, 2])
        #expect(queue.operationCount == 0)
        #expect(queue.isExecuting)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Completion waits for every operation in the queue")
    func completionWaitsForAllOperations() async {
        let queue = Queuer(name: "QueuerTestCompletionWaitsForAllOperations")
        let order = Protected<[String]>([])
        let completed = Protected(false)
        let releaseSlowOperation = DispatchSemaphore(value: 0)

        /// The slow operation is added first, the fast one last:
        /// the completion must wait for both, not just for the last added one.
        let slowOperation = ConcurrentOperation { _ in
            _ = releaseSlowOperation.wait(timeout: .now() + .seconds(8))
            order.append("slow")
        }
        let fastOperation = ConcurrentOperation { _ in
            order.append("fast")
        }
        queue.addOperation(slowOperation)
        queue.addOperation(fastOperation)

        queue.addCompletionHandler {
            order.append("done")
            completed.mutate { $0 = true }
        }

        releaseSlowOperation.signal()

        #expect(await waitUntil { completed.value })
        #expect(order.value.last == "done")
        #expect(Set(order.value) == ["slow", "fast", "done"])
    }
}
