//
//  SyntaxSugar.swift
//  Queuer
//
//  MIT License
//
//  Copyright (c) 2017 - 2024 Fabrizio Brancati
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

public extension Queuer {
    @discardableResult
    func add(_ operation: Operation) -> Queuer {
        addOperation(operation)
        return self
    }

    @discardableResult
    func maxConcurrentOperationCount(_ count: Int) -> Queuer {
        maxConcurrentOperationCount = count
        return self
    }

    @discardableResult
    func qualityOfService(_ quality: QualityOfService) -> Queuer {
        qualityOfService = quality
        return self
    }

    @discardableResult
    func completion(_ completion: @escaping () -> Void) -> Queuer {
        addCompletionHandler(completion)
        return self
    }

    @discardableResult
    func chained(_ operations: Operation...) -> Queuer {
        addChainedOperations(operations)
        return self
    }

//    @discardableResult
//    func chained(_ operations: Queuer...) -> Queuer {
//        addChainedOperations(operations)
//        return self
//    }

    @discardableResult
//     func concurrent(to queue: Queuer = self,_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> Queuer {
    func concurrent(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> Queuer {
        addOperation(ConcurrentOperation(executionBlock: block))
        return self
    }

    @discardableResult
    func group(_ group: ConcurrentOperation...) -> Queuer {
        addOperation(GroupOperation(group))
        return self
    }

    @available(macOS 13.0, iOS 16.0, *)
    @discardableResult
    func asyncWait<C>(_ time: C.Instant.Duration, tolerance: C.Instant.Duration? = nil, clock: C = ContinuousClock()) -> Queuer where C: Clock {
        let operation = ConcurrentOperation()
        operation.manualFinish = true
        operation.manualRetry = true
        operation.executionBlock { _ in
            Task {
                try? await Task.sleep<Never, Never>(for: time, tolerance: tolerance, clock: clock)
                operation.finish()
            }
        }
        add(operation)
        return self
    }

    @discardableResult
    func syncWait(_ time: TimeInterval) -> Queuer {
        let operation = ConcurrentOperation { _ in
            Thread.sleep(forTimeInterval: time)
        }
        add(operation)
        return self
    }
}

public extension ConcurrentOperation {
    @discardableResult
    func manualFinish(_ manualFinish: Bool = true) -> ConcurrentOperation {
        self.manualFinish = manualFinish
        return self
    }

    @discardableResult
    func manualRetry(_ manualRetry: Bool = true) -> ConcurrentOperation {
        self.manualRetry = manualRetry
        return self
    }

    @discardableResult
    func executionBlock(_ block: @escaping (_ operation: ConcurrentOperation) -> Void) -> ConcurrentOperation {
        executionBlock = block
        return self
    }

    @discardableResult
    func maximumRetries(_ retries: Int) -> ConcurrentOperation {
        maximumRetries = retries
        return self
    }
}
