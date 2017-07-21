//
//  Semaphore.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 Fabrizio Brancati
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
import Dispatch

/// DispatchSemaphore struct wrapper.
public struct Semaphore {
    /// Private DispatchSemaphore.
    private let semaphore = DispatchSemaphore(value: 0)
    
    /// Wait for a `continue` function call.
    @discardableResult
    public func wait() -> DispatchTimeoutResult {
        return self.semaphore.wait(timeout: .distantFuture)
    }
    
    /// This function returns non-zero if a thread is woken. Otherwise, zero is returned.
    ///
    /// - Returns: Returns non-zero if a thread is woken. Otherwise, zero is returned.
    public func `continue`() -> Int {
        return self.semaphore.signal()
    }
}
