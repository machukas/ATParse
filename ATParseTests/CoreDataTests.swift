//
//  CoreDataTests.swift
//  ATParse
//
//  Created by Aratech iOS on 30/5/17.
//  Copyright © 2017 AraTech. All rights reserved.
//

import XCTest
import CoreData
import Parse

@testable import ATParse
class CoreDataTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
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
	
	func downloadTestObjects(completion: @escaping (([ATParseObjectSubclass])->Void)) {
		let _: ATParseObjectSubclass? = ATParse().fetchObjects() { (error, objects) in
			completion(objects!)
		}
	}
	
	func downloadTest2Objects(completion: @escaping (([ATParseObjectSubclass2])->Void)) {
		let _: ATParseObjectSubclass2? = ATParse().fetchObjects() { (error, objects) in
			completion(objects!)
		}
	}
    
    func testExample() {
		
		let succesfullFetchExpectation = expectation(description: "Successfully fetched from network")
		
		self.downloadTest2Objects { objects in
			let object = objects[0]
			
			print("KEYS: -----------------")
			print("\(object.objectId!)")
			print("\(object.createdAt!)")
			for key in object.allKeys {
				print("\(key)")
				if let test = object.object(forKey: key) as? PFObject {
					print("isPFObject ---> TRUE, of className: \(test.parseClassName) with objectId: \(test.objectId!)")
				}
			}
			print("KEYS: -----------------")
			
			let test = Test(context: ATSyncEngine.persistentContainer.viewContext)
			if (test.entity.attributesByName["prueba"] != nil) {
				test.setValue("hola", forKey: "prueba")
			}
			ATSyncEngine.saveContext()
		}
		
		waitForExpectations(timeout: 30.0) { error in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
		}
    }
	
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}


class Test: NSManagedObject {
	
}

class Test2: NSManagedObject {
	
}

