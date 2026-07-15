//
//  SchedulerTests.swift
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

@Suite("Scheduler")
struct SchedulerTests {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Handler set after creation is called on every tick")
    func initWithoutHandler() async {
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        var schedule = Scheduler(deadline: .now(), repeating: .milliseconds(100))
        /// The timer is boxed since `DispatchSourceTimer` is not `Sendable`,
        /// and captured separately to avoid overlapping accesses to `schedule`
        /// between `setHandler(_:)` and the firing handler.
        let timer = Protected(schedule.timer)
        schedule.setHandler {
            /// Count the ticks instead of measuring time.
            /// Cancel on the fourth one, the timer's queue is serial so no other tick can race this.
            let count = order.mutate { value -> Int in
                value.append(0)
                return value.count
            }

            if count == 4 {
                timer.value.cancel()
                completed.mutate { $0 = true }
            }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value == [0, 0, 0, 0])
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Never repeating timer fires exactly once")
    func initWithHandler() async {
        let order = Protected<[Int]>([])

        let schedule = Scheduler(deadline: .now(), repeating: .never) {
            order.append(0)
        }

        #expect(await waitUntil { order.count >= 1 })
        /// A `.never` repeating timer must only fire once.
        /// Give it a short, bounded amount of time to (wrongly) fire again before asserting.
        try? await Task.sleep(nanoseconds: 300_000_000)
        #expect(order.value == [0])
        schedule.timer.cancel()
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Canceled timer stops firing")
    func cancel() async {
        let order = Protected<[Int]>([])

        var schedule = Scheduler(deadline: .now(), repeating: .milliseconds(100))
        /// The timer is boxed since `DispatchSourceTimer` is not `Sendable`.
        let timer = Protected(schedule.timer)
        schedule.setHandler {
            order.append(0)
            timer.value.cancel()
        }

        #expect(await waitUntil { order.count >= 1 })
        /// The timer has been canceled on the first tick.
        /// Give it a short, bounded amount of time to (wrongly) fire again before asserting.
        try? await Task.sleep(nanoseconds: 300_000_000)
        #expect(order.value == [0])
    }

    @Test("Scheduler without a handler is released safely")
    func initWithoutHandlerIsReleasedSafely() {
        /// A `Scheduler` created without a handler and never used
        /// must not crash when it is released.
        var schedule: Scheduler? = Scheduler(deadline: .now(), repeating: .seconds(10))
        schedule?.timer.cancel()
        schedule = nil

        #expect(schedule == nil)
    }

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    @Test("Handler can be replaced without crashing")
    func setHandlerTwice() async {
        let order = Protected<[Int]>([])
        let completed = Protected(false)

        /// The `Scheduler` is boxed, since a `@Sendable` closure cannot capture
        /// a mutable variable to call the mutating `setHandler(_:)`.
        let schedule = Protected(Scheduler(deadline: .now(), repeating: .milliseconds(100)))
        /// The timer is boxed since `DispatchSourceTimer` is not `Sendable`.
        let timer = Protected(schedule.value.timer)
        schedule.mutate {
            $0.setHandler {
                order.append(0)
            }
        }

        onBackgroundThread {
            guard waitUntil(timeout: 8, { order.value.contains(0) }) else { return }

            /// Setting the handler again must replace the previous one, without crashing.
            schedule.mutate {
                $0.setHandler {
                    let alreadyReplaced = order.mutate { value -> Bool in
                        let alreadyReplaced = value.contains(1)
                        value.append(1)
                        return alreadyReplaced
                    }

                    if !alreadyReplaced {
                        timer.value.cancel()
                        completed.mutate { $0 = true }
                    }
                }
            }
        }

        #expect(await waitUntil { completed.value })
        #expect(order.value.first == 0)
        #expect(order.value.contains(1))
    }
}
