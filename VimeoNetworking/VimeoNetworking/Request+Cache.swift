//
//  Request+Cache.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 4/14/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public extension Request
{
    var cacheKey: String
    {
        var cacheKey = self.path
        
        if let parameters = self.parameters
        {
            for (key, value) in parameters
            {
                cacheKey += key
                cacheKey += value
            }
        }
        
        cacheKey = cacheKey.replacingOccurrences(of: "/", with: ".")
        
        return cacheKey
    }
}
