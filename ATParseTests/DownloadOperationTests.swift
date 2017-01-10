//
//  DownloadOperationTests.swift
//  ATParse
//
//  Created by Aratech iOS on 10/1/17.
//  Copyright © 2017 AraTech. All rights reserved.
//

import XCTest
import XCGLogger
import Parse

@testable import ATParse

class DownloadOperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        if Parse.currentConfiguration() == nil {
            
            // Put setup code here. This method is called before the invocation of each test method in the class.
            let parseConfiguration = ParseConfiguration.Heroku.self
            let configuration = ParseClientConfiguration { (configuration) -> Void in
                
                configuration.applicationId = parseConfiguration.appID
                configuration.clientKey = parseConfiguration.clientKey
                configuration.server = parseConfiguration.server
            }
            
            Parse.initialize(with: configuration)
            
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCachedQuery(clearingCacheBefore: Bool = true) {
        
        let succesfullFetchExpectation = expectation(description: "Successfully fetched from cache")
        
        let operation: ParseClassObjectsDownloadOperation<ATParseObjectSubclass> = ParseClassObjectsDownloadOperation(cachePolicy: .cacheElseNetwork)
        
        if clearingCacheBefore { operation.query.clearCachedResult() }
        
        operation.completion = { error, objects in
            
            // Se ha generado la cache
            
            XCTAssert(operation.hasCachedResult)
            
            succesfullFetchExpectation.fulfill()
        }
        
        let queue = OperationQueues.parse
        
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 10.0) { error in
            if let error = error {
                XCGLogger.error("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testNetworkQuery() {
        let succesfullFetchExpectation = expectation(description: "Successfully fetched from network")
        
        let operation: ParseClassObjectsDownloadOperation<ATParseObjectSubclass> = ParseClassObjectsDownloadOperation(cachePolicy: .ignoreCache)
        
        operation.query.clearCachedResult()
        
        XCTAssert(!operation.hasCachedResult)
        
        operation.completion = { error, objects in
            
            // Se ha generado la cache
            
            XCTAssert(!operation.hasCachedResult)
            
            succesfullFetchExpectation.fulfill()
        }
        
        let queue = OperationQueues.parse
        
        queue.addOperation(operation)
        
        waitForExpectations(timeout: 10.0) { error in
            if let error = error {
                XCGLogger.error("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testPerformanceNetworkQuery() {
        self.measure {
            // Put the code you want to measure the time of here.
            self.testNetworkQuery()
        }
    }
    
    func testPerformanceCachedQuery() {
        // Llenamos cache
        self.testCachedQuery()
        self.measure {
            // Put the code you want to measure the time of here.
            self.testCachedQuery(clearingCacheBefore: false)
        }
    }
    
}
