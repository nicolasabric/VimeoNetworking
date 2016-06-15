//
//  ErrorCode.swift
//  VimeoNetworking
//
//  Created by Huebner, Rob on 4/25/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

public enum VimeoErrorCode: Int
{
    // Upload
    case uploadStorageQuotaExceeded = 4101
    case uploadDailyQuotaExceeded = 4102
    
    case invalidRequestInput = 2204 // root error code for all invalid parameters errors below
    
    // Password-protected video playback
    case videoPasswordIncorrect = 2222
    case noVideoPasswordProvided = 2223
    
    // Authentication
    case emailTooLong = 2216
    case passwordTooShort = 2210
    case passwordTooSimple = 2211
    case nameInPassword = 2212
    case emailNotRecognized = 2217
    case passwordEmailMismatch = 2218
    case noPasswordProvided = 2209
    case noEmailProvided = 2214
    case invalidEmail = 2215
    case noNameProvided = 2213
    case nameTooLong = 2208
    case facebookJoinInvalidToken = 2303
    case facebookJoinNoToken = 2306
    case facebookJoinMissingProperty = 2304
    case facebookJoinMalformedToken = 2305
    case facebookJoinDecryptFail = 2307
    case facebookJoinTokenTooLong = 2308
    case facebookLogInNoToken = 2312
    case facebookLogInMissingProperty = 2310
    case facebookLogInMalformedToken = 2311
    case facebookLogInDecryptFail = 2313
    case facebookLogInTokenTooLong = 2314
    case facebookInvalidInputGrantType = 2221
    case facebookJoinValidateTokenFail = 2315
    case facebookInvalidNoInput = 2207
    case facebookInvalidToken = 2300
    case facebookMissingProperty = 2301
    case facebookMalformedToken = 2302
    case emailAlreadyRegistered = 2400
    case emailBlocked = 2401
    case emailSpammer = 2402
    case emailPurgatory = 2403
    case urlUnavailable = 2404
    case timeout = 5000
    case tokenNotGenerated = 5001
}

public enum HTTPStatusCode: Int
{
    case serviceUnavailable = 503
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
}

public enum LocalErrorCode: Int
{
    // VimeoClient
    case undefined = 9000
    case invalidResponseDictionary = 9001
    case requestMalformed = 9002
    case cachedResponseNotFound = 9003
    
    // AuthenticationController
    case authToken = 9004
    case codeGrant = 9005
    case codeGrantState = 9006
    case noResponse = 9007
    case pinCodeInfo = 9008
    case pinCodeExpired = 9009
}
