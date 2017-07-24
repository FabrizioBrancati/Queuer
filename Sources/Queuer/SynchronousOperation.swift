//
//  SynchronousOperation.swift
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

public class SynchronousOperation: ConcurrentOperation {
    let semaphore = Semaphore()
    
    /// Set the Operation as synchronous.
    public override var isAsynchronous: Bool {
        return false
    }
    
    /// Notify the completion of sync task and hence the completion of the operation.
    /// Must be called when the Operation is finished.
    public override func finish() {
        self.semaphore.continue()
    }
    
    /// Advises the operation object that it should stop executing its task.
    public override func cancel() {
        super.cancel()
        
        self.semaphore.continue()
    }
    
    /// Execute the Operation.
    /// If `executionBlock` is set, it will be executed and also `finish()` will be called.
    public override func execute() {
        super.execute()
        
        self.semaphore.wait()
    }
}
