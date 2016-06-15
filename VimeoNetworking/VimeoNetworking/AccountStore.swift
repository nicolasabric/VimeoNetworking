//
//  AccountStore.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/24/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final internal class AccountStore
{
    enum AccountType: String
    {
        case ClientCredentials
        case User
    }
    
    // MARK: - 
    
    private let dataStore: SecureDataStore
    
    // MARK: -
    
    init(configuration: AppConfiguration)
    {
        self.dataStore = KeychainStore(service: configuration.keychainService, accessGroup: configuration.keychainAccessGroup)
    }
    
    // MARK: -
    
    func saveAccount(_ account: VIMAccount, type: AccountType) throws
    {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encodeObject(account)
        archiver.finishEncoding()
        
        try self.dataStore.setData(data, forKey: type.rawValue)
    }
    
    func loadAccount(_ type: AccountType) throws -> VIMAccount?
    {
        guard let data = try self.dataStore.dataForKey(type.rawValue)
        else
        {
            return nil
        }
        
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
        
        var account: VIMAccount? = nil
        
        try ExceptionCatcher.doUnsafe
        {
            account = unarchiver.decodeObject() as? VIMAccount
        }
        
        if let account = account,
            let userJSON = account.userJSON as? VimeoClient.ResponseDictionary
        {
            try account.user = VIMObjectMapper.mapObject(userJSON) as VIMUser
        }
        
        return account
    }
    
    func removeAccount(_ type: AccountType) throws
    {
        try self.dataStore.deleteDataForKey(type.rawValue)
    }
}
