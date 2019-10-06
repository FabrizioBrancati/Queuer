//
//  OperationState.swift
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

/// `Operation` State class.
/// Used to save the `Operation` State.
/// This class allows to save the current queue state.
public class OperationState: Codable {
    /// `Operation` name.
    public var name: String
    /// `Operation` progress.
    public var progress: Int
    /// `Operation` dependencies. It
    public var dependencies: [String]
    
    /// Initialize an `OperationState`.
    ///
    /// - Parameters:
    ///   - name: `Operation` name.
    ///   - progress: `Operation` progress.
    ///   - dependencies: `Operation` dependencies.
    public init(name: String, progress: Int, dependencies: [String]) {
        self.name = name
        self.progress = progress
        self.dependencies = dependencies
    }
}

/// `OperationState` extension to allow custom print of the class.
extension OperationState: CustomStringConvertible {
    public var description: String {
        return """
        Operation Name: \(name)
        Operation Progress: \(progress)
        Operation Dependencies: \(dependencies)
        """
    }
}
