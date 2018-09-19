//
//  ConcurrentOperation.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2018 Fabrizio Brancati
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

/// It allows asynchronous tasks, has a pause and resume states, can be easily added to a queue and can be created with a block.
open class ConcurrentOperation: Operation {
    /// Operation's execution block.
    public var executionBlock: ((_ operation: ConcurrentOperation) -> Void)?
    
    /// Creates the Operation with an execution block.
    ///
    /// - Parameter executionBlock: Execution block.
    public init(executionBlock: ((_ operation: ConcurrentOperation) -> Void)? = nil) {
        super.init()
        
        self.executionBlock = executionBlock
    }
    
    /// Set the Operation as asynchronous.
    override open var isAsynchronous: Bool {
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
    override open var isExecuting: Bool {
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
    override open var isFinished: Bool {
        return _finished
    }
    
    /// You should use `hasFailed` if retry is enabled.
    /// Set it to `true` if the operation has failed, otherwise `false`.
    /// Default is `false` to avoid retries.
    open var hasFailed = false
    
    /// Maximum allowed retries.
    open var maximumRetries = 3
    
    /// Current retry tentative.
    open var currentAttempt = 1
    
    /// Specify if the operation should retry another time.
    private var shouldRetry = true
    
    /// Start the Operation.
    override open func start() {
        _executing = true
        execute()
    }
    
    /// Execute the Operation.
    /// If `executionBlock` is set, it will be executed and also `finish()` will be called.
    open func execute() {
        if let executionBlock = executionBlock {
            while shouldRetry {
                executionBlock(self)
                self.finish(hasFailed)
            }
        }
    }
    
    /// Notify the completion of async task and hence the completion of the operation.
    /// Must be called when the Operation is finished.
    ///
    /// - Parameter hasFailed: Set it to `true` if the operation has failed, otherwise `false`.
    open func finish(_ hasFailed: Bool) {
        if !hasFailed || currentAttempt >= maximumRetries {
            _executing = false
            _finished = true
            shouldRetry = false
        } else {
            currentAttempt += 1
            shouldRetry = true
        }
    }
    
    /// Pause the current Operation, if it's supported.
    /// Must be overridend by subclass to get a custom pause action.
    open func pause() {}
    
    /// Resume the current Operation, if it's supported.
    /// Must be overridend by subclass to get a custom resume action.
    open func resume() {}
    
    /// Adds the Operation to `shared` Queuer.
    public func addToSharedQueuer() {
        Queuer.shared.addOperation(self)
    }
    
    /// Adds the Operation to the custom queue.
    ///
    /// - Parameter queue: Custom queue where the Operation will be added.
    public func addToQueue(_ queue: Queuer) {
        queue.addOperation(self)
    }
}
