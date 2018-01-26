//
//  ATParseTests.swift
//  ATParseTests
//
//  Created by Nicolas Landa on 21/12/16.
//  Copyright © 2016 Nicolas Landa. All rights reserved.
//

import XCTest
import Parse
import ATLogger
@testable import ATParse

class ATParseObjectSubclass: ATParseObject, PFSubclassing {
	
	convenience init(withKey key: String, value: Any) {
		self.init()
		
		self.setObject(value, forKey: key)
		self.setObject("name", forKey: "name")
	}
	
    class func parseClassName() -> String {
        return "Test"
    }
}

class ATParseTests: XCTestCase {
    
    var ignoringCacheATParse: ATParse = ATParse(withCachePolicy: .ignoreCache)
    var cacheElseNetworkATParse: ATParse = ATParse(withCachePolicy: .cacheElseNetwork)
    
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
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testReadParseConfigurationFromPlist() {
		
		let bundle: Bundle = Bundle(for: type(of: self))
		guard let filePath = bundle.path(forResource: "ParseConfiguration", ofType: "plist") else {
			NSLog("No configuration file found"); return
				XCTAssert(false, "No configuration file found")
		}
		
		let fileURL = URL(fileURLWithPath: filePath)
		
		let parseConfigurationFromURL = ParseClientConfiguration.readFrom(url: fileURL)
		let parseConfigurationFromString = ParseClientConfiguration.readFrom(string: filePath)
		
		let badURL = ParseClientConfiguration.readFrom(url: URL(fileURLWithPath: "badURL"))
		let badPath = ParseClientConfiguration.readFrom(string: "badPath")
		
		if parseConfigurationFromURL != nil && parseConfigurationFromString != nil,
			badURL == nil, badPath == nil {
			XCTAssert(true)
		} else {
			XCTAssert(false)
		}
	}
	
	func testATParseObject() {
		
		let atParseSubclass = ATParseObjectSubclass(withKey: "test", value: "test")
		
		atParseSubclass.setProperty("test2", forKey: "test")
		
		XCTAssert(atParseSubclass.property(forKey: "test")! == "test2")
		XCTAssert(atParseSubclass.itemDescription == "name")
	}
	
    func testATParseObjectSubclass() {
        
        let test: ATParseObjectSubclass = ATParseObjectSubclass()
        
        XCTAssert(test.property(forKey: "name")==nil)
    }
    
    func testParseCustomStringConvertible() {
        
        let test: ATParseObjectSubclass = ATParseObjectSubclass()
        
        test.setValue("aName", forKey: "name")
        
        XCTAssert((test.itemDescription)=="aName")
    }
	
	func testSyncFetch() {
		let query: PFQuery<ATParseObjectSubclass> = ATParseObjectSubclass.query()! as! PFQuery<ATParseObjectSubclass>
		let objects: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects(withQuery: query, async: false)
		
		XCTAssert(objects?.property(forKey: "name") == "test")
	}
    
    func testATParseFetch() {
    
        let succesfullFetchExpectation = expectation(description: "Successfully fetched into \(Parse.currentConfiguration()?.server ?? ""))")

		let query: PFQuery<ATParseObjectSubclass> = ATParseObjectSubclass.query() as! PFQuery<ATParseObjectSubclass>
		let _: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects(withQuery: query) { (error, objects) in

            XCTAssert(error == nil)
            log.info("\(objects ?? [])")

            succesfullFetchExpectation.fulfill()
        }

        waitForExpectations(timeout: 20.0) { error in
            if let error = error {
                log.error("Error: \(error.localizedDescription)")
            }
        }
    }
	
	func testATParseFullFetch() {
		
		let succesfullFetchExpectation = expectation(description: "Successfully fetched into \(Parse.currentConfiguration()?.server ?? ""))")

		let query: PFQuery<ATParseObjectSubclass> = ATParseObjectSubclass.query() as! PFQuery<ATParseObjectSubclass>
		let _: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects(withQuery: query, page: 0) { (error, objects) in

			XCTAssert(error == nil)
			XCTAssert(objects!.count > 1000)

			log.info("\(objects ?? [])")

			succesfullFetchExpectation.fulfill()
		}

		waitForExpectations(timeout: 20.0) { error in
			if let error = error {
				log.error("Error: \(error.localizedDescription)")
			}
		}
	}
	
	func testATParsePaginatedFetch() {
		
		let succesfullFetchExpectation = expectation(description: "Successfully fetched into \(Parse.currentConfiguration()?.server ?? ""))")
		
		let query: PFQuery<ATParseObjectSubclass> = ATParseObjectSubclass.query() as! PFQuery<ATParseObjectSubclass>
		let _: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects(withQuery: query, page: 2, orderedBy: [(.descending, "index")]) { (error, objects) in
			
			XCTAssert(error == nil)
			XCTAssert(objects!.count == 100)
			
			log.info("\(objects ?? [])")
			
			succesfullFetchExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 20.0) { error in
			if let error = error {
				log.error("Error: \(error.localizedDescription)")
			}
		}
	}
	
    func testATParseLoginAPI() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let succesfullLoginExpectation = expectation(description: "Successfully logging into \(Parse.currentConfiguration()?.server ?? ""))")
        
		self.ignoringCacheATParse.login(.normal(username: "apple", password: "12345")) { (error: UserError?, user: PFUser?, _) in
			
            XCTAssert(error == UserError.noError() && user?.value(forKey: "username") as? String == "apple")
            succesfullLoginExpectation.fulfill()
        }

        waitForExpectations(timeout: 20.0) { error in
            if let error = error {
                log.error("Error: \(error.localizedDescription)")
            }
        }
    }
	
	func testATParseOverloadOperator() {
		// This is an example of a functional test case.
		// Use XCTAssert and related functions to verify your tests produce the correct results.
		
		var leftObject = ATParseObjectSubclass(withoutDataWithObjectId: "12345")
		var righObject = ATParseObjectSubclass(withoutDataWithObjectId: "12345")
		
		XCTAssert(leftObject == righObject)
		
		leftObject = ATParseObjectSubclass(withoutDataWithObjectId: "12345")
		righObject = ATParseObjectSubclass(withoutDataWithObjectId: "123456")
		
		XCTAssert(leftObject != righObject)
	}
}
