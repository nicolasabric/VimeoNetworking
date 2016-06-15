//
//  ExceptionCatcher+Swift.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/26/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

class ExceptionCatcher: ObjC_ExceptionCatcher
{
    @nonobjc public static func doUnsafe(_ unsafeBlock: ((Void) -> Void)) throws
    {
        if let error = self._doUnsafe(unsafeBlock)
        {
            throw error
        }
    }
}
