//
//  Queuer.swift
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

/// Queuer class.
public class Queuer {
    /// Shared Queuer.
    public static let shared: Queuer = Queuer(name: "Queuer")
    
    /// Private OperationQueue.
    internal let queue: OperationQueue = OperationQueue()
    
    /// Total Operation count in queue.
    public var operationCount: Int {
        return self.queue.operationCount
    }
    
    /// Operations currently in queue.
    public var operations: [Operation] {
        return self.queue.operations
    }
    
    /// Returns if the queue is running or is in pause.
    /// Call `resume()` to make it running.
    /// Call `pause()` to make to pause it.
    public var isRunning: Bool {
        return !self.queue.isSuspended
    }
    
    /// Define the max concurrent operation count.
    public var maxConcurrentOperationCount: Int {
        get {
            return self.queue.maxConcurrentOperationCount
        }
        set {
            self.queue.maxConcurrentOperationCount = newValue
        }
    }
    
    /// Creates a new queue.
    ///
    /// - Parameter name: Custom queue name.
    public init(name: String) {
        self.queue.name = name
    }
    
    /// Add an Operation to be executed asynchronously.
    ///
    /// - Parameter block: Block to be executed.
    public func addOperation(_ operation: @escaping () -> Void) {
        self.queue.addOperation(operation)
    }
    
    /// Add an Operation to be executed asynchronously.
    ///
    /// - Parameter operation: Operation to be executed.
    public func addOperation(_ operation: Operation) {
        self.queue.addOperation(operation)
    }
    
    /// Add an Array of chained Operations.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionBlock.
    ///
    /// - Parameters:
    ///   - operations: Operations Array.
    ///   - completionBlock: Completion block to be exectuted when all Operations are finished.
    public func addChainedOperations(_ operations: [Operation], completionBlock: @escaping () -> Void) {
        let completionOperation: BlockOperation = BlockOperation(block: completionBlock)
        
        if !operations.isEmpty {
            var previousOperation: Operation?
            
            for operation: Operation in operations {
                if let previousOperation = previousOperation {
                    operation.addDependency(previousOperation)
                }
                
                previousOperation = operation
                
                self.addOperation(operation)
            }
            
            completionOperation.addDependency(operations[operations.count - 1])
        }
        
        self.addOperation(completionOperation)
    }
    
    /// Cancel all Operations in queue.
    public func cancelAll() {
        self.queue.cancelAllOperations()
        
        for operation in self.queue.operations {
            operation.cancel()
        }
    }
    
    /// Pause the queue.
    public func pause() {
        self.queue.isSuspended = true
    }
    
    /// Resume the queue.
    public func resume() {
        self.queue.isSuspended = false
    }
}
