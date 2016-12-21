//
//  Errors.swift
//  ATParse
//
//  Created by Aratech iOS on 21/12/16.
//  Copyright © 2016 AraTech. All rights reserved.
//

import Foundation
import XCGLogger

public protocol ParseError: Error {
    init?(withCode code: Int)
}

/// Casos de error:
///
/// - unknown: Desconocido
public enum ObjectError: ParseError {
    case unknown
    
    public init?(withCode code: Int) {
        XCGLogger.info("Initializing ParseError with code: \(code) ")
        switch code {
        case 200:
            return nil
        default:
            self = .unknown
        }
    }
    
    static func noError() -> ObjectError? {
        return ObjectError(withCode: 200)
    }
}

/// Casos de error:
///
/// - userAlreadyExists: Codigo 202 -> Usuario ya registrado
/// - emailAlreadyInUse: Código 203 -> Email ya en uso
/// - invalidUsernamePassword: Código 101 -> Combinación usuario contraseña invalida
/// - emailFormatInvalid: Codigo 125 -> Formato del email incorrecto
/// - userCancelledFacebookLogin: El usuario declinó logearse con Facebook
/// - unknown: Desconocido
public enum UserError: ParseError {
    case userAlreadyExists
    case emailAlreadyInUse
    case invalidUsernamePassword
    case emailFormatInvalid
    case userCancelledFacebookLogin
    case unknown
    
    public init?(withCode code: Int) {
        XCGLogger.info("Initializing UserError with code: \(code) ")
        switch code {
        case 101:
            self = .invalidUsernamePassword
        case 125:
            self = .emailFormatInvalid
        case 200:
            return nil
        case 202:
            self = .userAlreadyExists
        case 203:
            self = .emailAlreadyInUse
        default:
            self = .unknown
        }
    }
    
    static func noError() -> UserError? {
        return UserError(withCode: 200)
    }
}
