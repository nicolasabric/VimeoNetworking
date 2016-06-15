//
//  NSError+Extensions.swift
//  VimemoUpload
//
//  Created by Alfred Hanssen on 2/5/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import AFNetworking

public enum VimeoErrorKey: String
{
    case VimeoErrorCode = "VimeoLocalErrorCode" // Wish this could just be VimeoErrorCode but it conflicts with server-side key [AH] 2/5/2016
    case VimeoErrorDomain = "VimeoErrorDomain"
}

public extension NSError
{
    public var isServiceUnavailableError: Bool
    {
        return self.statusCode == HTTPStatusCode.serviceUnavailable.rawValue
    }
    
    public var isInvalidTokenError: Bool
    {
        if let urlResponse = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey] as? NSHTTPURLResponse
            where urlResponse.statusCode == HTTPStatusCode.Unauthorized.rawValue
        {
            if let header = urlResponse.allHeaderFields["WWW-Authenticate"] as? String
                where header == "Bearer error=\"invalid_token\""
            {
                return true
            }
        }
        
        return false
    }
    
    func isNetworkTaskCancellationError() -> Bool
    {
        return self.domain == NSURLErrorDomain && self.code == NSURLErrorCancelled
    }
    
    func isConnectionError() -> Bool
    {
        return [NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost].contains(self.code)
    }
    
    class func errorWithDomain(_ domain: String?, code: Int?, description: String?) -> NSError
    {
        var error = NSError(domain: VimeoErrorKey.VimeoErrorDomain.rawValue, code: 0, userInfo: nil)
        
        if let description = description
        {
            let userInfo = [NSLocalizedDescriptionKey: description]
            error = error.errorByAddingDomain(domain, code: code, userInfo: userInfo)
        }
        else
        {
            error = error.errorByAddingDomain(domain, code: code, userInfo: nil)
        }
        
        return error
    }

    func errorByAddingDomain(_ domain: String) -> NSError
    {
        return self.errorByAddingDomain(domain, code: nil, userInfo: nil)
    }
    
    func errorByAddingUserInfo(_ userInfo: [String: AnyObject]) -> NSError
    {
        return self.errorByAddingDomain(nil, code: nil, userInfo: userInfo)
    }
    
    func errorByAddingCode(_ code: Int) -> NSError
    {
        return self.errorByAddingDomain(nil, code: code, userInfo: nil)
    }
    
    func errorByAddingDomain(_ domain: String?, code: Int?, userInfo: [String: AnyObject]?) -> NSError
    {
        let augmentedInfo = NSMutableDictionary(dictionary: self.userInfo)
        
        if let domain = domain
        {
            augmentedInfo[VimeoErrorKey.VimeoErrorDomain.rawValue] = domain
        }
        
        if let code = code
        {
            augmentedInfo[VimeoErrorKey.VimeoErrorCode.rawValue] = code
        }
        
        if let userInfo = userInfo
        {
            augmentedInfo.addEntries(from: userInfo)
        }
        
        return NSError(domain: self.domain, code: self.code, userInfo: augmentedInfo as [NSObject: AnyObject])
    }
    
    // MARK: -
    
    private static let VimeoErrorCodeHeaderKey = "Vimeo-Error-Code"
    private static let VimeoErrorCodeKeyLegacy = "VimeoErrorCode"
    private static let VimeoErrorCodeKey = "error_code"
    
    public var statusCode: Int?
    {
        if let response = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey]
        {
            return response.statusCode
        }
        
        return nil
    }
    
    public var vimeoServerErrorCode: Int?
    {
        if let errorCode = (self.userInfo[self.dynamicType.VimeoErrorCodeKeyLegacy] as? NSNumber)?.intValue
        {
            return errorCode
        }
        
        if let response = self.userInfo[AFNetworkingOperationFailingURLResponseErrorKey],
            let headers = response.allHeaderFields,
            let vimeoErrorCode = (headers[self.dynamicType.VimeoErrorCodeHeaderKey] as? NSNumber)?.integerValue
        {
            return vimeoErrorCode
        }
        
        if let json = self.errorResponseBodyJSON,
            let errorCode = (json[self.dynamicType.VimeoErrorCodeKey] as? NSNumber)?.intValue
        {
            return errorCode
        }
        
        return nil
    }
    
    public var errorResponseBodyJSON: [String: AnyObject]?
    {
        if let data = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData
        {
            do
            {
                let json = try JSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
                
                return json
            }
            catch
            {
                return nil
            }
        }
        
        return nil
    }
}
