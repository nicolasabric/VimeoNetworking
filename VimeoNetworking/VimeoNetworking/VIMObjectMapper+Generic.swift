//
//  VIMObjectMapper+Generic.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 4/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

import VIMObjectMapper

extension VIMObjectMapper
{
    static var ErrorDomain: String { return "ObjectMapperErrorDomain" }
    static var ErrorNoMappingClass: Int { return 1002 }
    static var ErrorMappingFailed: Int { return 1003 }
    
    static func mapObject<ModelType: MappableResponse>(_ responseDictionary: VimeoClient.ResponseDictionary, modelKeyPath: String? = nil) throws -> ModelType
    {
        // Deserialize the dictionary into a model object
        
        guard let mappingClass = ModelType.mappingClass
            else
        {
            let description = "no mapping class found"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.ErrorDomain, code: self.ErrorNoMappingClass, userInfo: [NSLocalizedDescriptionKey: description])
            
            throw error
        }
        
        let objectMapper = VIMObjectMapper()
        let modelKeyPath = modelKeyPath ?? ModelType.modelKeyPath
        objectMapper.addMappingClass(mappingClass, forKeypath: modelKeyPath ?? "")
        var mappedObject = objectMapper.applyMappingToJSON(responseDictionary)
        
        if let modelKeyPath = modelKeyPath
        {
            mappedObject = (mappedObject as? VimeoClient.ResponseDictionary)?[modelKeyPath]
        }
        
        guard let modelObject = mappedObject as? ModelType
            else
        {
            let description = "couldn't map to ModelType"
            
            assertionFailure(description)
            
            let error = NSError(domain: self.ErrorDomain, code: self.ErrorMappingFailed, userInfo: [NSLocalizedDescriptionKey: description])
            
            throw error
        }
        
        return modelObject
    }
}
