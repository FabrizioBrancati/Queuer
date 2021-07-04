//
//  ConcurrentOperation.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2021 Fabrizio Brancati
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

/// It allows the creation of group `Operation`s by using it's `operations` array of `ConcurrentOperation`.
open class GroupOperation: ConcurrentOperation {
    /// Private `OperationQueue` instance.
    private let queue = OperationQueue()

    /// List of `ConcurrentOperation` that should be run in this `GroupOperation`.
    public var operations: [ConcurrentOperation] = []

    /// Flag to know if all `ConcurrentOperation` of this `GroupOperation` were successful.
    public var allOperationsSucceeded: Bool {
        return !operations.contains { !$0.success }
    }

    /// Creates the `GroupOperation` with a completion handler.
    /// Allows the execution of a block of `Operation`s with a completion handler that will be called
    /// once all the operations are finished.
    ///
    /// Example:
    ///
    ///     [A -> [[B & C & D] -> completionHandler] -> E] -> completionHandler
    ///
    /// - Parameters:
    ///     - operations: Array of ConcurrentOperation to be executed.
    ///     - completionHandler: Block that will be executed once all operations are over.
    public init(_ operations: [ConcurrentOperation], completionHandler: (() -> Void)? = nil) {
        super.init()

        self.operations = operations
        self.completionBlock = completionHandler
    }

    /// Execute the `Operation`
    /// The execution of a `GroupOperation` will always be considered successful.
    /// Use the variable `allOperationsSucceeded` to know if an error occurred on an operation in the Group.
    override open func execute() {
        queue.addOperations(operations, waitUntilFinished: true)
        finish(success: true)
    }
}
