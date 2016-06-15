//
//  Notification.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/25/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public class ObservationToken
{
    private let observer: NSObjectProtocol
    
    private init(observer: NSObjectProtocol)
    {
        self.observer = observer
    }
    
    public func stopObserving()
    {
        Notification.removeObserver(self.observer)
    }
    
    deinit
    {
        self.stopObserving()
    }
}

public enum Notification: String
{
    case ClientDidReceiveServiceUnavailableError
    case ClientDidReceiveInvalidTokenError
    
    case ReachabilityDidChange
    
    case AuthenticatedAccountDidChange
    case AuthenticatedAccountDidRefresh
    
    // MARK: -
    
    private static let NotificationCenter = Foundation.NotificationCenter.default()
    
    // MARK: -
    
    public func post(object: AnyObject?)
    {
        DispatchQueue.main.async
        {
            self.dynamicType.NotificationCenter.post(name: Foundation.Notification.Name(rawValue: self.rawValue), object: object)
        }
    }
    
    public func observe(_ target: AnyObject, selector: Selector)
    {
        self.dynamicType.NotificationCenter.addObserver(target, selector: selector, name: self.rawValue, object: nil)
    }
    
    @warn_unused_result(message : "Token must be strongly stored, observation ceases on token deallocation")
    public func observe(_ observationBlock: (Foundation.Notification) -> Void) -> ObservationToken
    {
        let observer = self.dynamicType.NotificationCenter.addObserver(forName: NSNotification.Name(rawValue: self.rawValue), object: nil, queue: OperationQueue.main(), using: observationBlock)
        
        return ObservationToken(observer: observer)
    }
    
    public func removeObserver(_ target: AnyObject)
    {
        self.dynamicType.NotificationCenter.removeObserver(target, name: NSNotification.Name(rawValue: self.rawValue), object: nil)
    }
    
    public static func removeObserver(_ target: AnyObject)
    {
        self.NotificationCenter.removeObserver(target)
    }
}
