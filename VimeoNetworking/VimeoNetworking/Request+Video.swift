//
//  Request+Video.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 4/5/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public typealias ToggleRequest = Request<VIMNullResponse>

public extension Request
{
    public static func watchLaterRequest(videoURI: String) -> Request
    {
        return Request(method: .PUT, path: "/users/10895030/likes/7235817")
    }
}
