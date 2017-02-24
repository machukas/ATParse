//
//  ATParseTests.swift
//  ATParseTests
//
//  Created by Nicolas Landa on 21/12/16.
//  Copyright © 2016 Nicolas Landa. All rights reserved.
//

import XCTest
import Parse
import XCGLogger
@testable import ATParse

/// Contiene las distintas configuraciones para conectar con un servidor Parse
public struct ParseConfiguration {
    /// Servidor de prueba alojado en Heroku
    struct Heroku {
        static let appID = "testingParseServer"
        static let clientKey = "123456789"
        static let server = "http://testing-purposes-parse-server.herokuapp.com/parse"
    }
}

class ATParseObjectSubclass: ATParseObject, PFSubclassing {
    
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
    
    func testSyncFetch() {
        let objects: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects(async: false)
        XCTAssert(objects?.property(forKey: "name") == "test")
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
    
    func testATParseFetch() {
    
        let succesfullFetchExpectation = expectation(description: "Successfully fetched into \(Parse.currentConfiguration()?.server))")
        
        let _: ATParseObjectSubclass? = self.ignoringCacheATParse.fetchObjects() { (error, objects) in
            
            XCTAssert(error == nil)
            XCGLogger.info("\(objects)")
            
            succesfullFetchExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 20.0) { error in
            if let error = error {
                XCGLogger.error("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testATParseLoginAPI() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let succesfullLoginExpectation = expectation(description: "Successfully logging into \(Parse.currentConfiguration()?.server))")
        
        self.ignoringCacheATParse.login(.normal(username: "apple", password: "12345")) { (error: UserError?, user: PFUser?) in
            
            XCTAssert(error == UserError.noError() && user?.value(forKey: "username") as? String == "apple")
            succesfullLoginExpectation.fulfill()
        }

        waitForExpectations(timeout: 20.0) { error in
            if let error = error {
                XCGLogger.error("Error: \(error.localizedDescription)")
            }
        }
    }
}
