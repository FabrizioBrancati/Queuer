//
//  QueuerSwiftTestingTests.swift
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

import Foundation
import Queuer
import Testing

/// A thread safe box around a value.
/// Tests mutate state from operation threads, so every shared value goes through this lock.
final class Locked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var lockedValue: Value

    init(_ value: Value) {
        lockedValue = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return lockedValue
    }

    func mutate(_ transform: @Sendable (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&lockedValue)
    }
}

/// Polls a condition until it becomes `true` or the timeout is reached,
/// without blocking any thread.
///
/// - Parameters:
///   - timeout: Maximum time to wait for the condition. Default is 10 seconds.
///   - condition: Condition to be verified.
/// - Returns: Returns `true` if the condition became true before the timeout, otherwise `false`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
func waitUntil(timeout: TimeInterval = 10, _ condition: @Sendable () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)

    while !condition() {
        guard Date() < deadline else {
            return false
        }

        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    return true
}

@Suite("Queuer with Swift Testing")
struct QueuerSwiftTestingTests {
    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Chained operations run in order")
    func chainedOperationsRunInOrder() async {
        let queue = Queuer(name: "SwiftTestingChainedOperations")
        let order = Locked<[Int]>([])
        let completed = Locked(false)

        queue.addChainedOperations(
            ConcurrentOperation { _ in
                order.mutate { $0.append(0) }
            },
            ConcurrentOperation { _ in
                order.mutate { $0.append(1) }
            }
        ) {
            order.mutate { $0.append(2) }
            completed.mutate { $0 = true }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 1, 2])
    }

    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Failed operations are retried three times")
    func automaticRetries() async {
        let queue = Queuer(name: "SwiftTestingAutomaticRetries")
        let attempts = Locked(0)

        let concurrentOperation = ConcurrentOperation { operation in
            attempts.mutate { $0 += 1 }
            operation.success = false
        }
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(attempts.value == 3)
        #expect(concurrentOperation.currentAttempt == 3)
        #expect(concurrentOperation.success == false)
    }

    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Group operations run all of their operations")
    func groupOperationRunsAllOperations() async {
        let queue = Queuer(name: "SwiftTestingGroupOperation")
        let executed = Locked<Set<String>>([])

        let groupOperation = GroupOperation(
            [
                ConcurrentOperation { _ in
                    executed.mutate { $0.insert("1") }
                },
                ConcurrentOperation { _ in
                    executed.mutate { $0.insert("2") }
                }
            ]
        )
        groupOperation.addToQueue(queue)

        #expect(await waitUntil { groupOperation.isFinished })
        #expect(executed.value == ["1", "2"])
        #expect(groupOperation.allOperationsSucceeded)
    }

    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceled operations never execute")
    func canceledOperationDoesNotExecute() async {
        let queue = Queuer(name: "SwiftTestingCanceledOperation")
        let executed = Locked(false)

        queue.pause()

        let concurrentOperation = ConcurrentOperation { _ in
            executed.mutate { $0 = true }
        }
        concurrentOperation.addToQueue(queue)

        queue.cancel()
        queue.resume()

        #expect(await waitUntil { queue.operationCount == 0 })
        #expect(executed.value == false)
        #expect(concurrentOperation.isCancelled)
    }

    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Operations without an execution block finish on their own")
    func operationWithoutExecutionBlockFinishes() async {
        let queue = Queuer(name: "SwiftTestingWithoutExecutionBlock")

        let concurrentOperation = ConcurrentOperation()
        concurrentOperation.addToQueue(queue)

        #expect(await waitUntil { concurrentOperation.isFinished })
        #expect(queue.operationCount == 0)
    }

    /// The availability is applied to the test function itself,
    /// Swift Testing does not support it on the suite.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Semaphore waits for its signal")
    func semaphoreSignalsCompletion() async {
        let queue = Queuer(name: "SwiftTestingSemaphore")
        let semaphore = Semaphore()
        let testString = Locked("")

        let concurrentOperation = ConcurrentOperation { _ in
            testString.mutate { $0 = "Tested" }
            semaphore.continue()
        }
        concurrentOperation.addToQueue(queue)

        #expect(semaphore.wait(.now() + .seconds(8)) == .success)
        #expect(testString.value == "Tested")
    }

    @Test("Syntactic sugar configures operations")
    func syntacticSugarConfiguresOperations() {
        let concurrentOperation = ConcurrentOperation()
            .name("SwiftTestingOperation")
            .queuePriority(.high)
            .qualityOfService(.utility)
            .manualFinish()
            .manualRetry()
            .maximumRetries(5)
            .executionBlock { _ in }

        #expect(concurrentOperation.name == "SwiftTestingOperation")
        #expect(concurrentOperation.queuePriority == .high)
        #expect(concurrentOperation.qualityOfService == .utility)
        #expect(concurrentOperation.manualFinish)
        #expect(concurrentOperation.manualRetry)
        #expect(concurrentOperation.maximumRetries == 5)
        #expect(concurrentOperation.executionBlock != nil)
    }

    @Test("Queuer is configurable")
    func queuerConfiguration() {
        let queue = Queuer(name: "SwiftTestingConfiguration", maxConcurrentOperationCount: 10, qualityOfService: .utility)

        #expect(queue.queue.name == "SwiftTestingConfiguration")
        #expect(queue.maxConcurrentOperationCount == 10)
        #expect(queue.qualityOfService == .utility)
        #expect(queue.isExecuting)
    }

    @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
    @Test("Async wait delays the queue without blocking a thread")
    func asyncWaitDelaysTheQueue() async {
        let queue = Queuer(name: "SwiftTestingAsyncWait")
        let completed = Locked(false)
        let start = Date()

        queue
            .asyncWait(.milliseconds(100))
            .completion {
                completed.mutate { $0 = true }
            }

        #expect(await waitUntil { completed.value })
        /// The wait must last at least the requested time.
        /// A lenient lower bound avoids failures from clock differences.
        #expect(Date().timeIntervalSince(start) >= 0.05)
    }
}
