//
//  AuthenticationController.swift
//  VimeoNetworkingExample-iOS
//
//  Created by Huebner, Rob on 3/21/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import Foundation

final public class AuthenticationController
{
    static let ErrorDomain = "AuthenticationControllerErrorDomain"
    
    private static let ResponseTypeKey = "response_type"
    private static let CodeKey = "code"
    private static let ClientIDKey = "client_id"
    private static let RedirectURIKey = "redirect_uri"
    private static let ScopeKey = "scope"
    private static let StateKey = "state"
    
    private static let CodeGrantAuthorizationPath = "oauth/authorize"
    
    private static let PinCodeRequestInterval: TimeInterval = 5
    
    public typealias AuthenticationCompletion = ResultCompletion<VIMAccount>.T
    
    /// State is tracked for the code grant request/response cycle, to avoid interception
    static let state = ProcessInfo.processInfo().globallyUniqueString
    
    let configuration: AppConfiguration
    let client: VimeoClient
    
    /// We need to use a separate client to make the actual auth requests, to ensure it's unauthenticated
    private let authenticatorClient: VimeoClient
    
    private let accountStore: AccountStore
    
    /// Set to false to stop the refresh cycle for pin code auth
    private var continuePinCodeAuthorizationRefreshCycle = true
    
    public init(client: VimeoClient)
    {
        self.configuration = client.configuration
        self.client = client
        self.accountStore = AccountStore(configuration: client.configuration)
        
        self.authenticatorClient = VimeoClient(appConfiguration: client.configuration)
    }
    
    // MARK: - Saved Accounts
    
    public func loadSavedAccount() throws -> VIMAccount?
    {
        var loadedAccount = try self.accountStore.loadAccount(.User)
        
        if loadedAccount == nil
        {
            loadedAccount = try self.accountStore.loadAccount(.ClientCredentials)
        }
        
        if let loadedAccount = loadedAccount
        {
            try self.authenticateClient(account: loadedAccount)
            
            print("loaded account \(loadedAccount)")
            
            // TODO: refresh user [RH] (4/25/16)
            
            // TODO: after refreshing user, send notification [RH] (4/25/16)
        }
        else
        {
            print("no account loaded")
        }
        
        return loadedAccount
    }
    
    // MARK: - Public Authentication
    
    public func clientCredentialsGrant(_ completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.clientCredentialsGrantRequest(scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public var codeGrantRedirectURI: String
    {
        let scheme = "vimeo\(self.configuration.clientKey)"
        let path = "auth"
        let URI = "\(scheme)://\(path)"
        
        return URI
    }
    
    public func codeGrantAuthorizationURL() -> URL
    {
        let parameters = [self.dynamicType.ResponseTypeKey: self.dynamicType.CodeKey,
                          self.dynamicType.ClientIDKey: self.configuration.clientKey,
                          self.dynamicType.RedirectURIKey: self.codeGrantRedirectURI,
                          self.dynamicType.ScopeKey: Scope.combine(self.configuration.scopes),
                          self.dynamicType.StateKey: self.dynamicType.state]
        
        guard let urlString = try! VimeoBaseURLString?.appendingPathComponent(self.dynamicType.CodeGrantAuthorizationPath)?.absoluteString
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        var error: NSError?
        let urlRequest = VimeoRequestSerializer(appConfiguration: self.configuration).requestWithMethod(VimeoClient.Method.GET.rawValue, URLString: urlString, parameters: parameters, error: &error)
        
        guard let url = urlRequest.url where error == nil
        else
        {
            fatalError("Could not make code grant auth URL")
        }
        
        return url
    }
    
    public func codeGrant(responseURL: URL, completion: AuthenticationCompletion)
    {
        guard let queryString = responseURL.query,
            let parameters = queryString.parametersFromQueryString(),
            let code = parameters[self.dynamicType.CodeKey],
            let state = parameters[self.dynamicType.StateKey]
        else
        {
            let errorDescription = "Could not retrieve parameters from code grant response"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.codeGrant.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        if state != self.dynamicType.state
        {
            let errorDescription = "Code grant returned state did not match existing state"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.codeGrantState.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        let request = AuthenticationRequest.codeGrantRequest(code: code, redirectURI: self.codeGrantRedirectURI)
        
        self.authenticate(request: request, completion: completion)
    }
    
    // MARK: - Private Authentication
    
    public func logIn(email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.logInRequest(email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func join(name: String, email: String, password: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinRequest(name: name, email: email, password: password, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func facebookLogIn(facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.logInFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    public func facebookJoin(facebookToken: String, completion: AuthenticationCompletion)
    {
        let request = AuthenticationRequest.joinFacebookRequest(facebookToken: facebookToken, scopes: self.configuration.scopes)
        
        self.authenticate(request: request, completion: completion)
    }
    
    /// Pin code authentication, for devices like Apple TV.
    
    public typealias PinCodeInfoHander = (pinCode: String, activateLink: String) -> Void
    
    public func pinCode(infoHandler: PinCodeInfoHander, completion: AuthenticationCompletion)
    {
        let infoRequest = PinCodeRequest.getPinCodeRequest(scopes: self.configuration.scopes)
        
        self.authenticatorClient.request(infoRequest) { result in
            switch result
            {
            case .Success(let result):
                
                let info = result.model
                
                guard let userCode = info.userCode,
                    let deviceCode = info.deviceCode,
                    let activateLink = info.activateLink
                    where info.expiresIn > 0
                else
                {
                    let errorDescription = "Malformed pin code info returned"
                    
                    assertionFailure(errorDescription)
                    
                    let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.PinCodeInfo.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
                    
                    completion(result: .Failure(error: error))
                    
                    return
                }
                
                infoHandler(pinCode: userCode, activateLink: activateLink)
                
                let expirationDate = NSDate(timeIntervalSinceNow: NSTimeInterval(info.expiresIn))
                
                self.continuePinCodeAuthorizationRefreshCycle = true
                self.doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode, expirationDate: expirationDate, completion: completion)
                
            case .Failure(let error):
                completion(result: .Failure(error: error))
            }
        }
    }
    
    private func doPinCodeAuthorization(userCode: String, deviceCode: String, expirationDate: Date, completion: AuthenticationCompletion)
    {
        guard Date().compare(expirationDate) == .orderedAscending
        else
        {
            let description = "Pin code expired"
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.pinCodeExpired.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
            
            completion(result: .Failure(error: error))
            
            return
        }
        
        let authorizationRequest = AuthenticationRequest.authorizePinCodeRequest(userCode: userCode, deviceCode: deviceCode)
        
        self.authenticate(request: authorizationRequest) { [weak self] result in
            
            switch result
            {
            case .Success:
                completion(result: result)
                
            case .Failure(let error):
                if error.statusCode == HTTPStatusCode.BadRequest.rawValue // 400: Bad Request implies the code hasn't been activated yet, so try again.
                {
                    guard let strongSelf = self
                        else
                    {
                        return
                    }
                    
                    if strongSelf.continuePinCodeAuthorizationRefreshCycle
                    {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(strongSelf.dynamicType.PinCodeRequestInterval * NSTimeInterval(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self] in
                            
                            self?.doPinCodeAuthorization(userCode: userCode, deviceCode: deviceCode, expirationDate: expirationDate, completion: completion)
                        }
                    }
                }
                else // Any other error is an actual error, and should get reported back.
                {
                    completion(result: result)
                }
            }
        }
    }
    
    public func cancelPinCode()
    {
        self.continuePinCodeAuthorizationRefreshCycle = false
    }
    
    // MARK: - Log out
    
    public func logOut() throws
    {
        guard self.client.isAuthenticatedWithUser == true
        else
        {
            return
        }
        
        let deleteTokensRequest = Request<VIMNullResponse>.deleteTokensRequest()
        self.client.request(deleteTokensRequest) { (result) in
            switch result
            {
            case .success:
                break
            case .failure(let error):
                print("could not delete tokens: \(error)")
            }
        }
        
        self.client.authenticatedAccount = nil
        
        try self.accountStore.removeAccount(.User)
    }
    
    // MARK: - Private
    
    private func authenticate(request: AuthenticationRequest, completion: AuthenticationCompletion)
    {
        self.authenticatorClient.request(request) { result in
            
            let handledResult = self.handleAuthenticationResult(result)
            
            completion(result: handledResult)
        }
    }
    
    private func handleAuthenticationResult(_ result: Result<Response<VIMAccount>>) -> Result<VIMAccount>
    {
        guard case .Success(let accountResponse) = result
        else
        {
            let resultError: NSError
            if case .Failure(let error) = result
            {
                resultError = error
            }
            else
            {
                let errorDescription = "Authentication result malformed"
                
                assertionFailure(errorDescription)
                
                resultError = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.noResponse.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            }
            
            return .Failure(error: resultError)
        }
        
        let account = accountResponse.model
        
        if let userJSON = accountResponse.json["user"] as? VimeoClient.ResponseDictionary
        {
            account.userJSON = userJSON
        }
        
        do
        {
            try self.authenticateClient(account: account)
            
            let accountType: AccountStore.AccountType = (account.user != nil) ? .User : .ClientCredentials
            
            try self.accountStore.saveAccount(account, type: accountType)
        }
        catch let error
        {
            return .Failure(error: error as NSError)
        }
        
        return .Success(result: account)
    }
    
    private func authenticateClient(account: VIMAccount) throws
    {
        guard account.accessToken != nil
        else
        {
            let errorDescription = "AuthenticationController did not recieve an access token with account response"
            
            assertionFailure(errorDescription)
            
            let error = NSError(domain: self.dynamicType.ErrorDomain, code: LocalErrorCode.authToken.rawValue, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            
            throw error
        }
        
        self.client.authenticatedAccount = account
    }
}
