//
//  Scheduler.swift
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

import Dispatch
import Foundation

/// Scheduler struct, based on top of `DispatchSourceTimer`.
public struct Scheduler {
    /// Schedule timer.
    public private(set) var timer: DispatchSourceTimer
    /// Schedule deadline.
    public private(set) var deadline: DispatchTime
    /// Schedule repeating interval.
    public private(set) var repeating: DispatchTimeInterval
    /// Schedule quality of service.
    public private(set) var qualityOfService: DispatchQoS
    /// Schedule handler.
    public private(set) var handler: (() -> Void)?
    
    /// Create a schedule.
    ///
    /// - Parameters:
    ///   - deadline: Deadline.
    ///   - repeating: Repeating interval
    ///   - qualityOfService: Quality of service.
    ///   - handler: Closure handler.
    public init(deadline: DispatchTime, repeating: DispatchTimeInterval, qualityOfService: DispatchQoS = .default, handler: (() -> Void)? = nil) {
        self.deadline = deadline
        self.repeating = repeating
        self.qualityOfService = qualityOfService
        self.handler = handler
        
        timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: deadline, repeating: repeating)
        if let handler = handler {
            timer.setEventHandler(qos: qualityOfService) {
                handler()
            }
            timer.resume()
        }
    }
    
    /// Set the handler after schedule creation.
    ///
    /// - Parameter handler: Closure handler.
    public mutating func setHandler(_ handler: @escaping () -> Void) {
        self.handler = handler
        
        timer.setEventHandler(qos: qualityOfService) {
            handler()
        }
        timer.resume()
    }
}
