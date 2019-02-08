//
//  GroupOperation.swift
//  Queuer
//
//  Created by Jerome Pasquier on 06/02/2019.
//  Copyright © 2019 Fabrizio Brancati. All rights reserved.
//

import Foundation

open class GroupOperation: ConcurrentOperation {
    /// Private `OperationQueue` instance
    private let queue = OperationQueue()
    
    /// List of `ConcurrentOperation` that should be run in this `GroupOperation`
    public var operations: [ConcurrentOperation] = []
    
    /// Flag to know if all `ConcurrentOperation` of this `GroupOperation` were successful
    public var allOperationsSucceeded: Bool {
        return operations.first(where: { $0.success == false }) == nil
    }
    
    /// Completion block that will run once all `operations` are finished
    public var completionHandler: ((_ operation: GroupOperation) -> Void)?
    
    /// Creates the `GroupOperation` with a completion handler
    ///
    /// - Parameters:
    ///     - operations: Array of ConcurrentOperation to be executed
    ///     - completionHandler: Block that will be executed once all operations are over
    public init(_ operations: [ConcurrentOperation], completionHandler: ((_ operation: GroupOperation) -> Void)? = nil) {
        super.init()
        self.operations = operations
        self.completionHandler = completionHandler
    }
    
    /// A `GroupOperation` shouldn't be able to retry itself. It should be the responsability of its operations to retry themselves.
    @available(*, obsoleted: 1.0, message: "Use retry on the children operations directly")
    open override func retry() {}
    
    /// Execute the `Operation`
    /// The execution of a `GroupOperation` will always be considered successful.
    /// Use the variable `allOperationsSucceeded` to know if an error occured on an operation in the Group.
    open override func execute() {
        queue.addOperations(operations, waitUntilFinished: true)
        finish(success: true)
        completionHandler?(self)
    }
}
