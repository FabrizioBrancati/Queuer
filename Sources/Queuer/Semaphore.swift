//
//  Semaphore.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2019 Fabrizio Brancati
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

/// `DispatchSemaphore` struct wrapper.
public struct Semaphore {
    /// Private `DispatchSemaphore`.
    private let semaphore: DispatchSemaphore
    
    /// Creates new counting semaphore with an initial value.
    /// Passing zero for the value is useful for when two threads need to reconcile
    /// the completion of a particular event. Passing a value greater than zero is
    /// useful for managing a finite pool of resources, where the pool size is equal
    /// to the value.
    ///
    /// - Parameter poolSize: The starting value for the semaphore.
    ///                       Passing a value less than zero will cause `nil` to be returned.
    public init(poolSize: Int = 0) {
        semaphore = DispatchSemaphore(value: poolSize)
    }
    
    /// Wait for a `continue` function call.
    ///
    /// - Parameter timeout: The timeout `DispatchTime`. Default is `.distantFuture`.
    /// - Returns: Returns a `DispatchTimeoutResult`.
    @discardableResult
    public func wait(_ timeout: DispatchTime = .distantFuture) -> DispatchTimeoutResult {
        return semaphore.wait(timeout: timeout)
    }
    
    /// This function returns non-zero if a thread is woken. Otherwise, zero is returned.
    ///
    /// - Returns: Returns non-zero if a thread is woken. Otherwise, zero is returned.
    @discardableResult
    public func `continue`() -> Int {
        return semaphore.signal()
    }
}
