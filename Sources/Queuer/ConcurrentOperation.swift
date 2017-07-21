//
//  ConcurrentOperation.swift
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

/// Concurrent Operation class.
public class ConcurrentOperation: Operation {
    /// Set the Operation as asynchronous.
    public override var isAsynchronous: Bool {
        return true
    }
    
    /// Set if the Operation is executing.
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    /// Set if the Operation is executing.
    override public var isExecuting: Bool {
        return _executing
    }
    
    /// Set if the Operation is finished.
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    /// Set if the Operation is finished.
    public override var isFinished: Bool {
        return _finished
    }
    
    /// Start the Operation.
    public override func start() {
        _executing = true
        execute()
    }
    
    /// Execute the Operation.
    public func execute() {}
    
    /// Notify the completion of async task and hence the completion of the operation.
    /// Must be called when the Operation is finished.
    public func finish() {
        _executing = false
        _finished = true
    }
    
    /// Add the Operation to `shared` Queuer.
    public func addToQueuer() {
        Queuer.shared.addOperation(self)
    }
}
