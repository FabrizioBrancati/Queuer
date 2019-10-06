//
//  SynchronousOperation.swift
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

import Foundation

/// It allows synchronous tasks, has a pause and resume states, can be easily added to a queue and can be created with a block.
public class SynchronousOperation: ConcurrentOperation {
    /// Private `Semaphore` instance.
    private let semaphore = Semaphore()
    
    /// Set the `Operation` as synchronous.
    override public var isAsynchronous: Bool {
        return false
    }
    
    /// Notify the completion of synchronous task and hence the completion of the `Operation`.
    /// Must be called when the `Operation` is finished.
    ///
    /// - Parameter success: Set it to `false` if the `Operation` has failed, otherwise `true`.
    ///                      Default is `true`.
    override public func finish(success: Bool = true) {
        super.finish(success: success)
        
        semaphore.continue()
    }
    
    /// Advises the `Operation` object that it should stop executing its task.
    override public func cancel() {
        super.cancel()
        
        semaphore.continue()
    }
    
    /// Execute the `Operation`.
    /// If `executionBlock` is set, it will be executed and also `finish()` will be called.
    override public func execute() {
        super.execute()
        
        semaphore.wait()
    }
}
