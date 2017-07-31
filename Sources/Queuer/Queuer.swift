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
import Dispatch

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
    
    /// The default service level to apply to operations executed using the queue.
    public var qualityOfService: QualityOfService {
        get {
            return self.queue.qualityOfService
        }
        set {
            self.queue.qualityOfService = newValue
        }
    }
    
    /// Returns if the queue is executing or is in pause.
    /// Call `resume()` to make it running.
    /// Call `pause()` to make to pause it.
    public var isExecuting: Bool {
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
    public init(name: String, maxConcurrentOperationCount: Int = Int.max, qualityOfService: QualityOfService = .default) {
        self.queue.name = name
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
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
    ///     [A, B, C] = A -> B -> C -> completionHandler.
    ///
    /// - Parameters:
    ///   - operations: Operations Array.
    ///   - completionHandler: Completion block to be exectuted when all Operations
    ///                        are finished.
    public func addChainedOperations(_ operations: [Operation], completionHandler: (() -> Void)? = nil) {
        for (index, operation) in operations.enumerated() {
            if index > 0 {
                operation.addDependency(operations[index - 1])
            }
            
            self.addOperation(operation)
        }
        
        guard let completionHandler = completionHandler else {
            return
        }
        
        let completionOperation = BlockOperation(block: completionHandler)
        if !operations.isEmpty {
            completionOperation.addDependency(operations[operations.count - 1])
        }
        self.addOperation(completionOperation)
    }
    
    /// Cancel all Operations in queue.
    public func cancelAll() {
        self.queue.cancelAllOperations()
    }
    
    /// Pause the queue.
    public func pause() {
        self.queue.isSuspended = true
        
        for operation in self.queue.operations where operation is ConcurrentOperation {
            (operation as? ConcurrentOperation)?.pause()
        }
    }
    
    /// Resume the queue.
    public func resume() {
        self.queue.isSuspended = false
        
        for operation in self.queue.operations where operation is ConcurrentOperation {
            (operation as? ConcurrentOperation)?.resume()
        }
    }
    
    /// Blocks the current thread until all of the receiver’s queued and executing
    /// operations finish executing.
    public func waitUntilAllOperationsAreFinished() {
        self.queue.waitUntilAllOperationsAreFinished()
    }
}
