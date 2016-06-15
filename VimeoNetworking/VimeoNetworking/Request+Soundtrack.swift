//
//  Request+Soundtrack.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Westendorf, Michael on 4/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public typealias SoundtrackListRequest = Request<[VIMSoundtrack]>

public extension Request
{
    private static var SoundtracksURI: String { return "/songs" }
    
    public static func getSoundtrackListRequest() -> Request
    {
        return self.getSoundtrackListRequest(soundtracksURI: self.SoundtracksURI)
    }
    
    public static func getSoundtrackListRequest(soundtracksURI: String) -> Request
    {
        return Request(path: soundtracksURI)
    }
}
