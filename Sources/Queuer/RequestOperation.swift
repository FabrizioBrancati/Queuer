//
//  RequestOperation.swift
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

#if !os(Linux)

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
    
    /// Global cache policy for all request.
    /// Also cache policy can be set per request.
    public static var globalCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
    
    /// Request task.
    private(set) public var task: URLSessionDataTask?
    /// Request URL.
    private(set) public var url: URL?
    /// Request query.
    private(set) public var query: String?
    /// Request complete URL
    private(set) public var completeURL: URL?
    /// Request timeout.
    private(set) public var timeout: TimeInterval = 30
    /// Request HTTP method.
    private(set) public var method: HTTPMethod = .get
    /// Request cache policy.
    private(set) public var cachePolicy: URLRequest.CachePolicy = globalCachePolicy
    /// Request headers.
    private(set) public var headers: [String: String]?
    /// Request body.
    private(set) public var body: Data?
    /// Request completionHandler.
    private(set) public var completionHandler: RequestClosure?
    
    /// URLSession instance.
    internal var session: URLSession {
        return URLSession.shared
    }
    
    /// URLRequest instance.
    private var request: URLRequest!
    
    /// Private init with executrion block.
    /// You can't create a RequestOperation with only an execution block.
    ///
    /// - Parameter block: Execution block.
    private override init(executionBlock: (() -> Void)? = nil) {
        super.init(executionBlock: nil)
    }
    
    /// Creates a RequestOperation, ready to be added in a queue.
    ///
    /// - Parameters:
    ///   - url: Request URL String.
    ///   - query: Request query. Default is nil.
    ///   - timeout: Request timeout. Default is 30 seconds.
    ///   - method: Request HTTP method. Default is `.get`.
    ///   - cachePolicy: Request cache policy. Use static var `globalCachePolicy` 
    ///                  to set a global cache policy for all the RequestOperations.
    ///   - headers: Request headers. Defatult is nil.
    ///   - body: Request body. Default is nil.
    ///   - completionHandler: Request completion handler. Default is nil.
    public convenience init(url: String, query: [String: String] = [:], timeout: TimeInterval = 30, method: HTTPMethod = .get, cachePolicy: URLRequest.CachePolicy = globalCachePolicy, headers: [String: String] = [:], body: Data? = nil, completionHandler: RequestClosure? = nil) {
        self.init()
        
        let query = URLBuilder.build(query: query)
        
        self.query = query
        self.url = URL(string: url)
        self.completeURL = URL(string: url + query)
        self.timeout = timeout
        self.method = method
        self.cachePolicy = cachePolicy
        self.headers = headers
        self.body = body
        self.completionHandler = completionHandler
    }
    
    /// Executes the request operation asynchronously.
    public override func execute() {
        /// Check if the Operation has been cancelled.
        guard !self.isCancelled else {
            if let completionHandler = completionHandler {
                completionHandler(false, nil, nil, RequestError.operationCancelled)
            }
            
            /// Notify that the Operation has finished execution.
            self.finish()
            
            return
        }
        
        /// Check if the URL can be used.
        guard let url = self.completeURL else {
            if let completionHandler = completionHandler {
                completionHandler(false, nil, nil, RequestError.urlError)
            }
            
            /// Notify that the Operation has finished execution.
            finish()
            
            return
        }
        
        /// Creates the request.
        request = URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeout)
        /// Set the HTTP method.
        request.httpMethod = method.rawValue
        /// Set the HTTP body.
        if let body = body {
            request.httpBody = body
        }
        /// Set all the HTTP headers.
        if let headers = headers {
            headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        }
        
        /// Create the task.
        task = session.dataTask(with: request) { [weak self] data, response, error in
            /// Check if the Operation has a completion handler, has an HTTP response
            /// and has not been canceled.
            if let strongSelf = self {
                if let completionHandler = strongSelf.completionHandler {
                    if let httpResponse = response as? HTTPURLResponse {
                        var error: Error? = error
                        /// Set `success` to true if the HTTP status code
                        /// is greater or equal than 200 and less than 400
                        /// and has not been cancelled.
                        let success: Bool = httpResponse.statusCode >= 200 && httpResponse.statusCode < 400 && !strongSelf.isCancelled
                        
                        /// Check again if the request has not been cancelled.
                        if strongSelf.isCancelled {
                            error = RequestError.operationCancelled
                        }
                        
                        completionHandler(success, httpResponse, data, error)
                    } else {
                        completionHandler(false, nil, data, error)
                    }
                }
                /// Notify that the Operation has finished execution.
                strongSelf.finish()
            }
        }
        /// Start the task.
        task?.resume()
    }
    
    /// Cancels the request operation.
    public override func cancel() {
        super.cancel()
        
        task?.cancel()
    }
    
    /// Suspends the request operation.
    public override func pause() {
        super.pause()
        
        task?.suspend()
    }
    
    /// Resumes the request operation.
    public override func resume() {
        super.resume()
        
        task?.resume()
    }
}

#endif
