//
//  VIMVideoTests.swift
//  VimeoNetworking
//
//  Created by Hawkins, Jason on 5/3/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//

import XCTest

class VIMVideoTests: XCTestCase {
    
    let testVideo = VIMVideo()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConnectionWithNameReturnsNilConenctionForEmptyString() {
        let testConnectionString = ""
        XCTAssertNil(self.testVideo.connectionWithName(testConnectionString))
    }
    
    func testConnectionWithNameReturnsExpectedVIMConnection() {
        
    }
    
    func testInteractionWithNameReturnsExpectedVIMInteraction() {
        
    }
    
    func testCanCommentReturnsTrueWhenEnabled() {
        
    }
    
    func testCanLikeReturnsTrueWhenEnabled() {
        
    }
    
    func testCanViewCommentsReturnsTrueWhenEnabled() {
        
    }
    
    func testIsVODReturnsTrueWhenVideoIsVOD() {
        
    }
    
    func testIsPrivateReturnsTrueWhenEnabled() {
        
    }
    
    func testIsAvailableReturnsTrueWhenAvailable() {
        
    }
    
    func testIsTranscodingReturnsTrueWhenTranscoding() {
        
    }
    
    func testIsUploadingReturnsTrueWhenUploading() {
        
    }
    
    func testIsLikedReturnsTrueWhenVideoIsLiked() {
        
    }
    
    func testIsWatchlaterReturnsTrueWhenVideoIsWatchLater() {
        
    }
    
    func testIsRatedAllAudiencesReturnsTrueWhenVideoIsRatedAllAudiences() {
        
    }
    
    func testIsNotYetRatedReturnsTrueWhenVideoIsNotYetRated() {
        
    }
    
    func testIsRatedMatureReturnsTrueWhenVideoIsRatedMature() {
        
    }
    
    func testLikesCountReturnsCorrectLikesCount() {
        
    }
    
    func testCommentsCountReturnsCorrectCommentsCount() {
        
    }
    
    func testSetIsLikedSetsVideoAsLiked() {
        
    }
    
    func testSetIsWatchLaterSetsVideoAsWatchLater() {
    
    }
}
