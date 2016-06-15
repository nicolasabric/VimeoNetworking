//
//  KeychainStore.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/24/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation
import Security

protocol SecureDataStore
{
    func setData(data: NSData, forKey key: String) throws
    
    func dataForKey(key: String) throws -> NSData?
    
    func deleteDataForKey(key: String) throws
}

final class KeychainStore: SecureDataStore
{
    let service: String
    let accessGroup: String?
    
    init(service: String, accessGroup: String?)
    {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    func setData(data: NSData, forKey key: String) throws
    {
        try self.deleteDataForKey(key)
        
        var query = self.queryForKey(key)
        
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock as String
        
        let status = SecItemAdd(query, nil)
        
        if status != errSecSuccess
        {
            throw self.errorForStatus(status)
        }
    }
    
    func dataForKey(key: String) throws -> NSData?
    {
        var query = self.queryForKey(key)
        
        query[kSecMatchLimit as String] = kSecMatchLimitOne as String
        query[kSecReturnData as String] = kCFBooleanTrue
        
        var attributes: AnyObject? = nil
        let status = SecItemCopyMatching(query, &attributes)
        let data = attributes as? NSData
        
        if status != errSecSuccess && status != errSecItemNotFound
        {
            throw self.errorForStatus(status)
        }
        
        return data
    }
    
    func deleteDataForKey(key: String) throws
    {
        let query = self.queryForKey(key)
        
        let status = SecItemDelete(query)
        
        if status != errSecSuccess && status != errSecItemNotFound
        {
            throw self.errorForStatus(status)
        }
    }
    
    // MARK: - 
    
    private func queryForKey(key: String) -> [String: AnyObject]
    {
        var query: [String: AnyObject] = [:]
        
        query[kSecClass as String] = kSecClassGenericPassword as String
        query[kSecAttrService as String] = self.service
        query[kSecAttrAccount as String] = key
        
        if let accessGroup = self.accessGroup
        {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func errorForStatus(status: OSStatus) -> NSError
    {
        let errorMessage: String
        
        switch status
        {
        case errSecSuccess:
            errorMessage = "success"
        case errSecUnimplemented:
            errorMessage = "Function or operation not implemented."
        case errSecParam:
            errorMessage = "One or more parameters passed to the function were not valid."
        case errSecAllocate:
            errorMessage = "Failed to allocate memory."
        case errSecNotAvailable:
            errorMessage = "No trust results are available."
        case errSecAuthFailed:
            errorMessage = "Authorization/Authentication failed."
        case errSecDuplicateItem:
            errorMessage = "The item already exists."
        case errSecItemNotFound:
            errorMessage = "The item cannot be found."
        case errSecInteractionNotAllowed:
            errorMessage = "Interaction with the Security Server is not allowed."
        case errSecDecode:
            errorMessage = "Unable to decode the provided data."
        default:
            errorMessage = "undefined error"
        }
        
        let error = NSError(domain: "KeychainErrorDomain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
        return error
    }
}

/// Using this rly dumb dummy store until we finish keychain support [RH]

final class ArchiveStore: SecureDataStore
{
    private let fileManager = NSFileManager.defaultManager()
    
    func setData(data: NSData, forKey key: String) throws
    {
        let fileURL = self.fileURLForKey(key: key)
        
        guard let filePath = fileURL.path
        else
        {
            let error = NSError(domain: "ArchiveStoreDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "no path"])
            throw error
        }
        
        if let documentsDirectoryURL = self.documentsDirectoryURL()
        {
            try self.fileManager.createDirectoryAtURL(documentsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        if self.fileManager.fileExistsAtPath(filePath)
        {
            try self.fileManager.removeItemAtPath(filePath)
        }
        
        let success = self.fileManager.createFileAtPath(filePath, contents: data, attributes: nil)
        
        if !success
        {
            let error = NSError(domain: "ArchiveStoreDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "create file failed"])
            throw error
        }
    }
    
    func dataForKey(key: String) throws -> NSData?
    {
        let data = NSData(contentsOfURL: self.fileURLForKey(key: key))
        
        return data
    }
    
    func deleteDataForKey(key: String) throws
    {
        try self.fileManager.removeItemAtURL(self.fileURLForKey(key: key))
    }
    
    private func documentsDirectoryURL() -> NSURL?
    {
        if let directory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
        {
            return NSURL(fileURLWithPath: directory)
        }
        
        return nil
    }
    
    private func fileURLForKey(key key: String) -> NSURL
    {
        guard let directoryURL = self.documentsDirectoryURL()
        else
        {
            fatalError("no documents directories found")
        }
        
        let fileURL = directoryURL.URLByAppendingPathComponent("dontlookatthis-\(key).plist")
        
        return fileURL!
    }
}
