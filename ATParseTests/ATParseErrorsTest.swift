//
//  ATParseErrorsTest.swift
//  ATParseTests
//
//  Created by Aratech iOS on 26/1/18.
//  Copyright © 2018 AraTech. All rights reserved.
//

import XCTest
@testable import ATParse

class ATParseErrorsTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObjectError() {
		let code200Error = ObjectError(withCode: 200)
		let unknown = ObjectError(withCode: 400)
		let noError = ObjectError.noError()
		
		XCTAssert(code200Error == nil)
		XCTAssert(unknown == .unknown)
		XCTAssert(noError == nil)
    }
    
	func testUserError() {
		let userAlreadyExists = UserError(withCode: 202)
		let emailAlreadyInUse = UserError(withCode: 203)
		let invalidUsernamePassword = UserError(withCode: 101)
		let emailFormatInvalid = UserError(withCode: 125)
		let noError = UserError(withCode: 200) ?? UserError.noError()
		let schemaMismatch = UserError(withCode: 111)
		let unknown = UserError(withCode: 400)
		
		XCTAssert(userAlreadyExists == .userAlreadyExists)
		XCTAssert(emailAlreadyInUse == .emailAlreadyInUse)
		XCTAssert(invalidUsernamePassword == .invalidUsernamePassword)
		XCTAssert(emailFormatInvalid == .emailFormatInvalid)
		XCTAssert(noError == nil)
		XCTAssert(schemaMismatch == .schemaMismatch)
		XCTAssert(unknown == .unknown)
	}
}
