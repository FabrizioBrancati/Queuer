//
//  RequestOperation.swift
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

/// HTTP Method enum.
public enum HTTPMethod: String {
    /// CONNECT method.
    case connect = "CONNECT"
    /// DELETE method.
    case delete = "DELETE"
    /// GET method.
    case get = "GET"
    /// HEAD method.
    case head = "HEAD"
    /// OPTIONS method.
    case options = "OPTIONS"
    /// PATCH method.
    case patch = "PATCH"
    /// POST method.
    case post = "POST"
    /// PUT method.
    case put = "PUT"
}

/// RequestOperation helps you to create network operation with an easy interface.
public class RequestOperation: ConcurrentOperation {
    /// Custom HTTP errors.
    public enum RequestError: Error {
        /// URL doesn't exist.
        case urlError
        /// Operation has been cancelled.
        case operationCancelled
    }
    
    /// Request closure alias.
    public typealias RequestClosure = (Bool, HTTPURLResponse?, Data?, Error?) -> Void
    
    /// Request task.
    private(set) public var task: URLSessionDataTask?
    /// Request URL.
    private(set) public var url: URL?
    /// Request query.
    private(set) public var query: String = ""
    /// Request complete URL
    private var completeURL: URL?
    /// Request timeout.
    private(set) public var timeout: TimeInterval = 30
    /// Request HTTP method.
    private(set) public var method: HTTPMethod = .get
    /// Request headers.
    private(set) public var headers: [String: String] = [:]
    /// Request body.
    private(set) public var body: Data = Data()
    /// Request completionHandler.
    private(set) public var completionHandler: RequestClosure?
    
    /// URLSession instance.
    private var session: URLSession {
        return URLSession.shared
    }
    
    /// Cannot be initialized without parameters.
    private override init() {}
    
    /// Creates a ReqeustOperation, ready to be added in a queue.
    ///
    /// - Parameters:
    ///   - url: Request URL String.
    ///   - query: Request query.
    ///   - timeout: Request timeout.
    ///   - method: Request HTTP method.
    ///   - headers: Request headers.
    ///   - body: Request body.
    ///   - completionHandler: Request completion handler.
    public init(url: String, query: [String: String] = [:], timeout: TimeInterval = 30, method: HTTPMethod = .get, headers: [String: String] = [:], body: Data = Data(), completionHandler: RequestClosure? = nil) {
        self.query = URLBuilder.build(query: query)
        self.url = URL(string: url)
        self.completeURL = URL(string: url + self.query)
        self.timeout = timeout
        self.method = method
        self.headers = headers
        self.body = body
        self.completionHandler = completionHandler
    }
    
    /// Execute the request operation asynchronously.
    public override func execute() {
        /// Check if the Operation has been cancelled.
        guard !self.isCancelled else {
            if let completionHandler = self.completionHandler {
                completionHandler(false, nil, nil, RequestError.operationCancelled)
            }
            
            self.finish()
            
            return
        }
        
        /// Check if the URL can be used.
        guard let url = self.completeURL else {
            if let completionHandler = self.completionHandler {
                completionHandler(false, nil, nil, RequestError.urlError)
            }
            
            self.finish()
            
            return
        }
        
        /// Create the request.
        var request: URLRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: self.timeout)
        /// Set the HTTP method.
        request.httpMethod = method.rawValue
        /// Set the HTTP body.
        request.httpBody = body
        /// Set all the HTTP headers.
        for header in headers {
            request.value(forHTTPHeaderField: header.key) != nil ? request.setValue(header.value, forHTTPHeaderField: header.key) : request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        /// Create the task.
        self.task = self.session.dataTask(with: request) { data, response, error in
            /// Check if the Operation has a completion handler, an HTTP response and is not cancelled.
            if let completionHandler = self.completionHandler {
                if let httpResponse = response as? HTTPURLResponse {
                    var error: Error? = error
                    /// Set `success` to true if the HTTP status code
                    /// is greater or equal than 200 and less than 400
                    /// and has not been cancelled.
                    let success: Bool = httpResponse.statusCode >= 200 && httpResponse.statusCode < 400 && !self.isCancelled
                    
                    /// Check again if the request has not been cancelled.
                    if self.isCancelled {
                        error = RequestError.operationCancelled
                    }
                    
                    completionHandler(success, httpResponse, data, error)
                } else {
                    completionHandler(false, nil, data, error)
                }
            }
            self.finish()
        }
        /// Start the task.
        self.task?.resume()
    }
    
    /// Cancel the request operation.
    public override func cancel() {
        super.cancel()
        
        self.task?.cancel()
    }
    
    /// Suspend the request operation.
    public func suspend() {
        self.task?.suspend()
    }
    
    /// Resume the request operation.
    public func resume() {
        self.task?.resume()
    }
}
