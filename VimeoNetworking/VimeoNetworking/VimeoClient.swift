//
//  VimeoClient.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final public class VimeoClient
{
    // MARK: - 
    
    public enum Method: String
    {
        case GET
        case POST
        case PUT
        case PATCH
        case DELETE
    }
    
    public struct RequestToken
    {
        private let task: URLSessionDataTask
        
        func cancel()
        {
            self.task.cancel()
        }
    }
    
    public typealias RequestParameters = [String: String]
    public typealias ResponseDictionary = [String: AnyObject]
    
    static let ErrorDomain = "VimeoClientErrorDomain"
    
    // MARK: -
    
    private let sessionManager: VimeoSessionManager
    private let responseCache = ResponseCache()
    
    public init(appConfiguration: AppConfiguration)
    {
        self.configuration = appConfiguration
        self.sessionManager = VimeoSessionManager.defaultSessionManager(appConfiguration: appConfiguration)
    }
    
    // MARK: - Configuration
    
    public private(set) var configuration: AppConfiguration
    
    // MARK: - Authentication
    
    public var authenticatedAccount: VIMAccount?
    {
        didSet
        {
            if let authenticatedAccount = self.authenticatedAccount
            {
                self.sessionManager.clientDidAuthenticateWithAccount(authenticatedAccount)
            }
            else
            {
                self.sessionManager.clientDidClearAccount()
            }
            
            Notification.AuthenticatedAccountDidChange.post(object: self.authenticatedAccount)
        }
    }
    
    public var authenticatedUser: VIMUser?
    {
        return self.authenticatedAccount?.user
    }
    
    public var isAuthenticated: Bool
    {
        return self.authenticatedAccount?.isAuthenticated() ?? false
    }
    
    public var isAuthenticatedWithUser: Bool
    {
        return self.authenticatedAccount?.isAuthenticatedWithUser() ?? false
    }
    
    public var isAuthenticatedWithClientCredentials: Bool
    {
        return self.authenticatedAccount?.isAuthenticatedWithClientCredentials() ?? false
    }
    
    // MARK: - Request
    
    public func request<ModelType: MappableResponse>(_ request: Request<ModelType>, completionQueue: DispatchQueue = DispatchQueue.main, completion: ResultCompletion<Response<ModelType>>.T) -> RequestToken?
    {
        var networkRequestCompleted = false
        
        switch request.cacheFetchPolicy
        {
        case .cacheOnly, .cacheThenNetwork:
            
            self.responseCache.responseForRequest(request) { result in
                
                if networkRequestCompleted
                {
                    // If the network request somehow completes before the cache, abort any cache action [RH] (4/21/16)
                    
                    return
                }
                
                switch result
                {
                case .success(let response):
                    
                    if let response = response
                    {
                        completionQueue.async
                        {
                            completion(result: .success(result: response))
                        }
                    }
                    else if request.cacheFetchPolicy == .cacheOnly
                    {
                        let description = "Cached response not found"
                        let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.cachedResponseNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
                        
                        self.handleError(error, request: request)
                        
                        completionQueue.async
                        {
                            completion(result: .failure(error: error))
                        }
                    }
                    else
                    {
                        // no action required for a cache miss with a network request pending [RH]
                    }
                    
                case .failure(let error):
                    
                    print("cache failure: \(error)")
                    
                    self.handleError(error, request: request)
                    
                    if request.cacheFetchPolicy == .cacheOnly
                    {
                        completionQueue.async
                        {
                            completion(result: .failure(error: error))
                        }
                    }
                    else
                    {
                        // no action required for a cache error with a network request pending [RH]
                    }
                }
            }
            
            if request.cacheFetchPolicy == .cacheOnly
            {
                return nil
            }
            
        case .networkOnly, .tryNetworkThenCache:
            break
        }
        
        let urlString = request.path
        let parameters = request.parameters
        
        let success: (URLSessionDataTask, AnyObject?) -> Void = { (task, responseObject) in
            networkRequestCompleted = true
            self.handleTaskSuccess(request: request, task: task, responseObject: responseObject, completionQueue: completionQueue, completion: completion)
        }
        
        let failure: (URLSessionDataTask?, NSError) -> Void = { (task, error) in
            networkRequestCompleted = true
            self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
        }
        
        let task: URLSessionDataTask?
        
        switch request.method
        {
        case .GET:
            task = self.sessionManager.GET(urlString, parameters: parameters, success: success, failure: failure)
        case .POST:
            task = self.sessionManager.POST(urlString, parameters: parameters, success: success, failure: failure)
        case .PUT:
            task = self.sessionManager.PUT(urlString, parameters: parameters, success: success, failure: failure)
        case .PATCH:
            task = self.sessionManager.PATCH(urlString, parameters: parameters, success: success, failure: failure)
        case .DELETE:
            task = self.sessionManager.DELETE(urlString, parameters: parameters, success: success, failure: failure)
        }
        
        guard let requestTask = task
        else
        {
            let description = "Session manager did not return a task"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.requestMalformed.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            networkRequestCompleted = true
            
            self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
            
            return nil
        }
        
        return RequestToken(task: requestTask)
    }
    
    // MARK: - Task callbacks
    
    private func handleTaskSuccess<ModelType: MappableResponse>(request: Request<ModelType>, task: URLSessionDataTask, responseObject: AnyObject?, completionQueue: DispatchQueue, completion: ResultCompletion<Response<ModelType>>.T)
    {
        guard let responseDictionary = responseObject as? ResponseDictionary
        else
        {
            if ModelType.self == VIMNullResponse.self
            {
                let nullResponseObject = VIMNullResponse()
                
                // Swift complains that this cast always fails, but it doesn't seem to ever actually fail, and it's required to call completion with this response [RH] (4/12/2016)
                // It's also worth noting that (as of writing) there's no way to direct the compiler to ignore specific instances of warnings in Swift :S [RH] (4/13/16)
                let response = Response(model: nullResponseObject, json: [:]) as! Response<ModelType>

                completionQueue.async
                {
                    completion(result: .success(result: response as Response<ModelType>))
                }
            }
            else
            {
                let description = "VimeoClient requestSuccess returned invalid/absent dictionary"
                
                assertionFailure(description)
                
                let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.invalidResponseDictionary.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
                
                self.handleTaskFailure(request: request, task: task, error: error, completionQueue: completionQueue, completion: completion)
            }
            
            return
        }
        
        do
        {
            let modelObject: ModelType = try VIMObjectMapper.mapObject(responseDictionary, modelKeyPath: request.modelKeyPath)
            
            // To avoid a poisoned cache, explicitly wait until model object parsing is successful to store responseDictionary [RH]
            if request.shouldCacheResponse
            {
                self.responseCache.setResponse(responseDictionary, forRequest: request)
            }
            
            completionQueue.async
            {
                completion(result: .success(result: Response<ModelType>(model: modelObject, json: responseDictionary)))
            }
        }
        catch let error
        {
            self.handleTaskFailure(request: request, task: task, error: error as? NSError, completionQueue: completionQueue, completion: completion)
        }
    }
    
    private func handleTaskFailure<ModelType: MappableResponse>(request: Request<ModelType>, task: URLSessionDataTask?, error: NSError?, completionQueue: DispatchQueue, completion: ResultCompletion<Response<ModelType>>.T)
    {
        let error = error ?? NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.undefined.rawValue, userInfo: [NSLocalizedDescriptionKey: "Undefined error"])
        
        if error.code == NSURLErrorCancelled
        {
            return
        }
        
        self.handleError(error, request: request)
        
        if case .multipleAttempts(let attemptCount, let initialDelay) = request.retryPolicy
            where attemptCount > 1
        {
            var retryRequest = request
            retryRequest.retryPolicy = .multipleAttempts(attemptCount: attemptCount - 1, initialDelay: initialDelay * 2)
            
            DispatchQueue.main.after(when: DispatchTime.now() + Double(Int64(initialDelay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC))
            {
                self.request(retryRequest, completionQueue: completionQueue, completion: completion)
            }
        }
        
        else if request.cacheFetchPolicy == .tryNetworkThenCache
        {
            var cacheRequest = request
            cacheRequest.cacheFetchPolicy = .cacheOnly
            
            self.request(cacheRequest, completionQueue: completionQueue, completion: completion)
            
            return
        }
        
        completionQueue.async
        {
            completion(result: .failure(error: error))
        }
    }
    
    // MARK: - Error handling
    
    private func handleError<ModelType: MappableResponse>(_ error: NSError, request: Request<ModelType>)
    {
        if error.isServiceUnavailableError
        {
            Notification.ClientDidReceiveServiceUnavailableError.post(object: nil)
        }
        else if error.isInvalidTokenError
        {
            Notification.ClientDidReceiveInvalidTokenError.post(object: nil)
        }
    }
}

