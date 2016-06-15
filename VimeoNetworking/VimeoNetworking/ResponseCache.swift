//
//  ResponseCache.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/29/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final internal class ResponseCache
{
    func setResponse<ModelType>(_ responseDictionary: VimeoClient.ResponseDictionary, forRequest request: Request<ModelType>)
    {
        let key = request.cacheKey
        
        self.memoryCache.setResponseDictionary(responseDictionary, forKey: key)
        self.diskCache.setResponseDictionary(responseDictionary, forKey: key)
    }
    
    func responseForRequest<ModelType>(_ request: Request<ModelType>, completion: ResultCompletion<Response<ModelType>?>.T)
    {
        let key = request.cacheKey
        
        if let responseDictionary = self.memoryCache.responseDictionaryForKey(key)
        {
            do
            {
                let modelObject: ModelType = try VIMObjectMapper.mapObject(responseDictionary, modelKeyPath: request.modelKeyPath)
                let response = Response(model: modelObject, json: responseDictionary, isCachedResponse: true, isFinalResponse: request.cacheFetchPolicy == .cacheOnly)
                
                completion(result: .success(result: response))
            }
            catch let error
            {
                self.memoryCache.removeResponseDictionaryForKey(key)
                self.diskCache.removeResponseDictionaryForKey(key)
                
                completion(result: .failure(error: error as NSError))
            }
        }
        else
        {
            self.diskCache.responseDictionaryForKey(key) { responseDictionary in
                
                if let responseDictionary = responseDictionary
                {
                    do
                    {
                        let modelObject: ModelType = try VIMObjectMapper.mapObject(responseDictionary, modelKeyPath: request.modelKeyPath)
                        let response = Response(model: modelObject, json: responseDictionary, isCachedResponse: true, isFinalResponse: request.cacheFetchPolicy == .cacheOnly)
                        
                        completion(result: .success(result: response))
                    }
                    catch let error
                    {
                        self.diskCache.removeResponseDictionaryForKey(key)
                        
                        completion(result: .failure(error: error as NSError))
                    }
                }
                else
                {
                    completion(result: .success(result: nil))
                }
            }
        }
    }

    func removeResponseForRequest<ModelType>(_ request: Request<ModelType>)
    {
        let key = request.cacheKey
        
        self.memoryCache.removeResponseDictionaryForKey(key)
        self.diskCache.removeResponseDictionaryForKey(key)
    }
    
    func clear()
    {
        self.memoryCache.removeAllResponses()
        self.diskCache.removeAllResponses()
    }
    
    // MARK: - Memory Cache
    
    private let memoryCache = ResponseMemoryCache()
    
    private class ResponseMemoryCache
    {
        private let cache = Cache()
        
        func setResponseDictionary(_ responseDictionary: VimeoClient.ResponseDictionary, forKey key: String)
        {
            self.cache.setObject(responseDictionary, forKey: key)
        }
        
        func responseDictionaryForKey(_ key: String) -> VimeoClient.ResponseDictionary?
        {
            let object = self.cache.object(forKey: key) as? VimeoClient.ResponseDictionary
            
            return object
        }
        
        func removeResponseDictionaryForKey(_ key: String)
        {
            self.cache.removeObject(forKey: key)
        }
        
        func removeAllResponses()
        {
            self.cache.removeAllObjects()
        }
    }
    
    // MARK: - Disk Cache
    
    private let diskCache = ResponseDiskCache()
    
    private class ResponseDiskCache
    {
        private let queue = DispatchQueue(label: "com.vimeo.VIMCache.diskQueue", attributes: DispatchQueueAttributes.concurrent)
        
        func setResponseDictionary(_ responseDictionary: VimeoClient.ResponseDictionary, forKey key: String)
        {
            self.queue.async {
                
                let data = NSKeyedArchiver.archivedData(withRootObject: responseDictionary)
                
                let fileManager = FileManager()
                
                let directoryURL = self.cachesDirectoryURL()
                let fileURL = self.fileURLForKey(key: key)
                
                guard let directoryPath = directoryURL.path,
                    let filePath = fileURL.path
                else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                do
                {
                    if !fileManager.fileExists(atPath: directoryPath)
                    {
                        try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    let success = fileManager.createFile(atPath: filePath, contents: data, attributes: nil)
                    
                    if !success
                    {
                        print("ResponseDiskCache could not store object")
                    }
                }
                catch let error
                {
                    print("ResponseDiskCache error: \(error)")
                }
            }
        }
        
        func responseDictionaryForKey(_ key: String, completion: ((VimeoClient.ResponseDictionary?) -> Void))
        {
            self.queue.async {
                
                let fileURL = self.fileURLForKey(key: key)
                
                guard let filePath = fileURL.path
                    else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath))
                else
                {
                    completion(nil)
                    
                    return
                }
                
                var responseDictionary: VimeoClient.ResponseDictionary? = nil
                
                do
                {
                    try ExceptionCatcher.doUnsafe
                    {
                        responseDictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? VimeoClient.ResponseDictionary
                    }
                }
                catch let error
                {
                    print("error decoding response dictionary: \(error)")
                }
                
                completion(responseDictionary)
            }
        }
        
        func removeResponseDictionaryForKey(_ key: String)
        {
            self.queue.async {
                
                let fileManager = FileManager()
                
                let fileURL = self.fileURLForKey(key: key)
                
                guard let filePath = fileURL.path
                    else
                {
                    assertionFailure("no cache path found: \(fileURL)")
                    
                    return
                }
                
                do
                {
                    try fileManager.removeItem(atPath: filePath)
                }
                catch
                {
                    print("could not remove disk cache for \(key)")
                }
            }
        }
        
        func removeAllResponses()
        {
            self.queue.async {
                
                let fileManager = FileManager()
                
                guard let directoryPath = self.cachesDirectoryURL().path
                else
                {
                    assertionFailure("no cache directory")
                    
                    return
                }
                
                do
                {
                    try fileManager.removeItem(atPath: directoryPath)
                }
                catch
                {
                    print("could not clear disk cache")
                }
            }
        }
        
        // MARK: - directories
        
        private func cachesDirectoryURL() -> URL
        {
            guard let directory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
            else
            {
                fatalError("no cache directories found")
            }
            
            return URL(fileURLWithPath: directory)
        }
        
        private func fileURLForKey(key: String) -> URL
        {
            let directoryURL = self.cachesDirectoryURL()
            
            let fileURL = try! directoryURL.appendingPathComponent(key)
            
            return fileURL
        }
    }
}
