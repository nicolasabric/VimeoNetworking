//
//  String+Utilities.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public extension String
{
    func parametersFromQueryString() -> [String: String]?
    {
        var parameters: [String: String] = [:]
        
        let scanner = Scanner(string: self)
        while !scanner.isAtEnd
        {
            var name: NSString?
            let equals = "="
            scanner.scanUpTo(equals, into: &name)
            scanner.scanString(equals, into: nil)
            
            var value: NSString?
            let ampersand = "&"
            scanner.scanUpTo(ampersand, into: &value)
            scanner.scanString(ampersand, into: nil)
            
            if let name = name?.replacingPercentEscapes(using: String.Encoding.utf8.rawValue),
                let value = value?.replacingPercentEscapes(using: String.Encoding.utf8.rawValue)
            {
                parameters[name] = value
            }
        }
        
        return parameters.count > 0 ? parameters : nil
    }
}
