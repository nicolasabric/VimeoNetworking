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
    
    func testConnectionWithNameReturnsNilConnectionForEmptyString() {
        let testConnectionString = ""
        XCTAssertNil(self.testVideo.connectionWithName(testConnectionString))
    }
    
    func testConnectionWithNameReturnsNilConnectionForUnrecognizedString() {
        let testConnectionString = "asdfghjkl;"
        XCTAssertNil(self.testVideo.connectionWithName(testConnectionString))
    }
    
    func testConnectionWithNameReturnsExpectedVIMConnection() {
        // Not sure how to test this.
    }
    
    func testInteractionWithNameReturnsNilInteractionForEmptyString() {
        let testInteractionString = ""
        XCTAssertNil(self.testVideo.interactionWithName(testInteractionString))
    }
    
    func testInteractionWithNameReturnsNilInteractionForUnrecognizedString() {
        let testIneractionString = "asdfghjkl;"
        XCTAssertNil(self.testVideo.interactionWithName(testIneractionString))
    }
    
    func testInteractionWithNameReturnsExpectedVIMInteraction() {
        // Not sure how to test this.
    }
    
//    func testCanCommentReturnsTrueWhenEnabled() {
//        
//    }
//    
//    func testCanLikeReturnsTrueWhenEnabled() {
//        
//    }
//    
//    func testCanViewCommentsReturnsTrueWhenEnabled() {
//        
//    }
//    
//    func testIsVODReturnsTrueWhenVideoIsVOD() {
//        
//    }
//    
//    func testIsPrivateReturnsTrueWhenEnabled() {
//        
//    }
//    
//    func testIsAvailableReturnsTrueWhenAvailable() {
//        
//    }
//    
//    func testIsTranscodingReturnsTrueWhenTranscoding() {
//        
//    }
//    
//    func testIsUploadingReturnsTrueWhenUploading() {
//        
//    }
//    
//    func testIsLikedReturnsTrueWhenVideoIsLiked() {
//        
//    }
//    
//    func testIsWatchlaterReturnsTrueWhenVideoIsWatchLater() {
//        
//    }
//    
//    func testIsRatedAllAudiencesReturnsTrueWhenVideoIsRatedAllAudiences() {
//        
//    }
//    
//    func testIsNotYetRatedReturnsTrueWhenVideoIsNotYetRated() {
//        
//    }
//    
//    func testIsRatedMatureReturnsTrueWhenVideoIsRatedMature() {
//        
//    }
//    
//    func testLikesCountReturnsCorrectLikesCount() {
//        
//    }
//    
//    func testCommentsCountReturnsCorrectCommentsCount() {
//        
//    }
//    
//    func testSetIsLikedSetsVideoAsLiked() {
//        // The following test fails. That's not awesome.
//        self.testVideo.setIsLiked(true)
//        XCTAssertTrue(self.testVideo.isLiked())
//    }
//    
//    func testSetIsWatchLaterSetsVideoAsWatchLater() {
//        
//    }
}
