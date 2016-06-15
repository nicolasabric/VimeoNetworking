//
//  VimeoSessionManager+Constructors.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public extension VimeoSessionManager
{
    // MARK: - Default Session Initialization
    
    static func defaultSessionManager(accessToken: String) -> VimeoSessionManager
    {
        let sessionConfiguration = URLSessionConfiguration.default()
        let requestSerializer = VimeoRequestSerializer(accessTokenProvider: { accessToken })
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    static func defaultSessionManager(accessTokenProvider: VimeoRequestSerializer.AccessTokenProvider) -> VimeoSessionManager
    {
        let sessionConfiguration = URLSessionConfiguration.default()
        let requestSerializer = VimeoRequestSerializer(accessTokenProvider: accessTokenProvider)
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    static func defaultSessionManager(appConfiguration: AppConfiguration) -> VimeoSessionManager
    {
        let sessionConfiguration = URLSessionConfiguration.default()
        let requestSerializer = VimeoRequestSerializer(appConfiguration: appConfiguration)
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    // MARK: - Background Session Initialization
    
    static func backgroundSessionManager(identifier: String, accessToken: String) -> VimeoSessionManager
    {
        let sessionConfiguration = self.backgroundSessionConfiguration(identifier: identifier)
        let requestSerializer = VimeoRequestSerializer(accessTokenProvider: { accessToken })
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    static func backgroundSessionManager(identifier: String, accessTokenProvider: VimeoRequestSerializer.AccessTokenProvider) -> VimeoSessionManager
    {
        let sessionConfiguration = self.backgroundSessionConfiguration(identifier: identifier)
        let requestSerializer = VimeoRequestSerializer(accessTokenProvider: accessTokenProvider)
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    static func backgroundSessionManager(identifier: String, appConfiguration: AppConfiguration) -> VimeoSessionManager
    {
        let sessionConfiguration = self.backgroundSessionConfiguration(identifier: identifier)
        let requestSerializer = VimeoRequestSerializer(appConfiguration: appConfiguration)
        
        return VimeoSessionManager(sessionConfiguration: sessionConfiguration, requestSerializer: requestSerializer)
    }
    
    // MARK: Private API
    
    // Would prefer that this live in a NSURLSessionConfiguration extension but the method name would conflict [AH] 2/5/2016
    
    private static func backgroundSessionConfiguration(identifier: String) -> URLSessionConfiguration
    {
        let sessionConfiguration: URLSessionConfiguration
        
        if #available(iOS 8.0, OSX 10.10, *)
        {
            sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        }
        else
        {
            sessionConfiguration = URLSessionConfiguration.backgroundSessionConfiguration(identifier)
        }
        
        return sessionConfiguration
    }
}
