//
//  TestHelper.swift
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

/// A thread safe box around a value.
/// Tests mutate state from operation threads, so every shared value goes through this lock.
final class Protected<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var protectedValue: Value

    init(_ value: Value) {
        protectedValue = value
    }

    var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return protectedValue
    }

    @discardableResult
    func mutate<T>(_ transform: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return transform(&protectedValue)
    }
}

extension Protected where Value: RangeReplaceableCollection {
    func append(_ element: Value.Element) {
        mutate { $0.append(element) }
    }

    var count: Int {
        value.count
    }
}

/// Polls a condition until it becomes `true` or the timeout is reached,
/// blocking the current thread.
/// Use it only on background threads, like the ones driving manual retries.
///
/// - Parameters:
///   - timeout: Maximum time to wait for the condition. Default is 10 seconds.
///   - condition: Condition to be verified.
/// - Returns: Returns `true` if the condition became true before the timeout, otherwise `false`.
@discardableResult
func waitUntil(timeout: TimeInterval = 10, _ condition: () -> Bool) -> Bool {
    /// The deadline uses a monotonic clock: the wall clock can jump,
    /// for example when an emulator syncs its time, and would burn the budget.
    let deadline = DispatchTime.now() + timeout

    while !condition() {
        guard DispatchTime.now() < deadline else {
            return false
        }

        Thread.sleep(forTimeInterval: 0.02)
    }

    return true
}

/// Polls a condition until it becomes `true` or the timeout is reached,
/// without blocking any thread.
///
/// - Parameters:
///   - timeout: Maximum time to wait for the condition. Default is 10 seconds.
///   - condition: Condition to be verified.
/// - Returns: Returns `true` if the condition became true before the timeout, otherwise `false`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@discardableResult
func waitUntil(timeout: TimeInterval = 10, _ condition: @Sendable () -> Bool) async -> Bool {
    /// The deadline uses a monotonic clock: the wall clock can jump,
    /// for example when an emulator syncs its time, and would burn the budget.
    let deadline = DispatchTime.now() + timeout

    while !condition() {
        guard DispatchTime.now() < deadline else {
            return false
        }

        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    return true
}

/// Runs a block on a background thread.
/// Useful to drive manual retries or cancellations without relying on wall clock delays,
/// and without blocking the cooperative thread pool.
///
/// - Parameter block: Block to be executed.
func onBackgroundThread(_ block: @escaping @Sendable () -> Void) {
    DispatchQueue.global().async(execute: block)
}
