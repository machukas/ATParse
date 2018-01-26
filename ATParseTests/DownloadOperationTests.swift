//
//  DownloadOperationTests.swift
//  ATParse
//
//  Created by Aratech iOS on 10/1/17.
//  Copyright © 2017 AraTech. All rights reserved.
//

import XCTest
import Parse

@testable import ATParse

class DownloadOperationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

		if Parse.currentConfiguration() == nil {
			
			// Put setup code here. This method is called before the invocation of each test method in the class.
			
			let bundle: Bundle = Bundle(for: type(of: self))
			guard let filePath = bundle.path(forResource: "ParseConfiguration", ofType: "plist") else {
				NSLog("No configuration file found"); return
					XCTAssert(false, "No configuration file found")
			}
			
			let fileURL = URL(fileURLWithPath: filePath)
			
			if let parseConfiguration = ParseClientConfiguration.readFrom(url: fileURL) {
				Parse.initialize(with: parseConfiguration)
			} else {
				XCTAssert(false, "No configuration file found")
			}
		}
    }
	
	lazy var query: PFQuery<ATParseObjectSubclass> = {
		return ATParseObjectSubclass.query() as! PFQuery<ATParseObjectSubclass>
	}()
	
	var cachedQueryOperation: ParseClassObjectsDownloadOperation<ATParseObjectSubclass> {
		let query: PFQuery<ATParseObjectSubclass> = self.query
		let operation: ParseClassObjectsDownloadOperation<ATParseObjectSubclass> = ParseClassObjectsDownloadOperation(query: query, cachePolicy: .cacheElseNetwork)
		return operation
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func cachedQuery() {
        
        let succesfullFetchExpectation = expectation(description: "Successfully fetched from cache")

        let operation = self.cachedQueryOperation
		operation.completion = { error, objects in
			succesfullFetchExpectation.fulfill()
		}

        let queue = OperationQueues.parse

        queue.addOperation(operation)

        waitForExpectations(timeout: 10.0) { error in
            if let error = error {
                NSLog("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testNetworkQuery() {
        let succesfullFetchExpectation = expectation(description: "Successfully fetched from network")
		
		let query: PFQuery<ATParseObjectSubclass> = ATParseObjectSubclass.query() as! PFQuery<ATParseObjectSubclass>
		let operation: ParseClassObjectsDownloadOperation<ATParseObjectSubclass> = ParseClassObjectsDownloadOperation(query: query, cachePolicy: .ignoreCache)
		
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
                NSLog("Error: \(error.localizedDescription)")
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
        self.measure {
            // Put the code you want to measure the time of here.
            self.cachedQuery()
        }
    }
}
