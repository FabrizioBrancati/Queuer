//
//  Queuer.swift
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

/// Queuer class.
public class Queuer {
    /// Shared Queuer.
    public static let shared = Queuer(name: "Queuer")
    
    /// Queuer `OperationQueue`.
    public let queue = OperationQueue()
    
    /// Total `Operation` count in queue.
    public var operationCount: Int {
        return queue.operationCount
    }
    
    /// `Operation`s currently in queue.
    public var operations: [Operation] {
        return queue.operations
    }
    
    /// The default service level to apply to `Operation`s executed using the queue.
    public var qualityOfService: QualityOfService {
        get {
            return queue.qualityOfService
        }
        set {
            queue.qualityOfService = newValue
        }
    }
    
    /// Returns if the queue is executing or is in pause.
    /// Call `resume()` to make it running.
    /// Call `pause()` to make to pause it.
    public var isExecuting: Bool {
        return !queue.isSuspended
    }
    
    /// Define the max concurrent `Operation`s count.
    public var maxConcurrentOperationCount: Int {
        get {
            return queue.maxConcurrentOperationCount
        }
        set {
            queue.maxConcurrentOperationCount = newValue
        }
    }
    
    /// Creates a new queue.
    ///
    /// - Parameters:
    ///   - name: Custom queue name.
    ///   - maxConcurrentOperationCount: The max concurrent `Operation`s count.
    ///   - qualityOfService: The default service level to apply to `Operation`s executed using the queue.
    public init(name: String, maxConcurrentOperationCount: Int = Int.max, qualityOfService: QualityOfService = .default) {
        queue.name = name
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
    }
    
    /// Cancel all `Operation`s in queue.
    public func cancelAll() {
        queue.cancelAllOperations()
    }
    
    /// Pause the queue.
    public func pause() {
        queue.isSuspended = true
        
        for operation in queue.operations {
            if let concurrentOperation = operation as? ConcurrentOperation {
                concurrentOperation.pause()
            }
        }
    }
    
    /// Resume the queue.
    public func resume() {
        queue.isSuspended = false
        
        for operation in queue.operations {
            if let concurrentOperation = operation as? ConcurrentOperation {
                concurrentOperation.resume()
            }
        }
    }
    
    /// Blocks the current thread until all of the receiver’s queued and executing
    /// `Operation`s finish executing.
    public func waitUntilAllOperationsAreFinished() {
        queue.waitUntilAllOperationsAreFinished()
    }
}

// MARK: - Queuer Operations and Chaining

/// `Queuer` extension with `Operation`s and chaining handling.
public extension Queuer {
    /// Add an `Operation` to be executed asynchronously.
    ///
    /// - Parameter block: Block to be executed.
    func addOperation(_ operation: @escaping () -> Void) {
        queue.addOperation(operation)
    }
    
    /// Add an `Operation` to be executed asynchronously.
    ///
    /// - Parameter operation: `Operation` to be executed.
    func addOperation(_ operation: Operation) {
        queue.addOperation(operation)
    }
    
    /// Add an Array of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionHandler.
    ///
    /// - Parameters:
    ///   - operations: `Operation`s Array.
    ///   - completionHandler: Completion block to be exectuted when all `Operation`s
    ///                        are finished.
    func addChainedOperations(_ operations: [Operation], completionHandler: (() -> Void)? = nil) {
        for (index, operation) in operations.enumerated() {
            if index > 0 {
                operation.addDependency(operations[index - 1])
            }
            
            addOperation(operation)
        }
        
        guard let completionHandler = completionHandler else {
            return
        }
        
        addCompletionHandler(completionHandler)
    }
    
    /// Add an Array of chained `Operation`s.
    ///
    /// Example:
    ///
    ///     [A, B, C] = A -> B -> C -> completionHandler.
    ///
    /// - Parameters:
    ///   - operations: `Operation`s list.
    ///   - completionHandler: Completion block to be exectuted when all `Operation`s
    ///                        are finished.
    func addChainedOperations(_ operations: Operation..., completionHandler: (() -> Void)? = nil) {
        addChainedOperations(operations, completionHandler: completionHandler)
    }
    
    /// Add a completion block to the queue.
    ///
    /// - Parameter completionHandler: Completion handler to be executed as last `Operation`.
    func addCompletionHandler(_ completionHandler: @escaping () -> Void) {
        let completionOperation = BlockOperation(block: completionHandler)
        if let lastOperation = operations.last {
            completionOperation.addDependency(lastOperation)
        }
        addOperation(completionOperation)
    }
}

// MARK: - Queue State Restoration

/// `Queuer` extension with state restoration feature.
public extension Queuer {
    /// `OperationState` array typealias.
    typealias QueueStateList = [OperationState]
    
    /// Creates the queue state.
    ///
    /// - Returns: Returns the current queue state.
    func state() -> QueueStateList {
        return Queuer.state(of: queue)
    }
    
    /// Creates the state of a given queue.
    ///
    /// - Parameter queue: State will be created starting from this `OperationQueue`.
    /// - Returns: Returns the current queue state.
    static func state(of queue: OperationQueue) -> QueueStateList {
        var operations: QueueStateList = []
        
        for operation in queue.operations {
            if let concurrentOperation = operation as? ConcurrentOperation, let operationName = concurrentOperation.name {
                operations.append(OperationState(name: operationName, progress: concurrentOperation.progress, dependencies: operation.dependencies.compactMap { $0.name }))
            }
        }
        
        return operations
    }
}
