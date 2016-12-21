//
//  API.swift
//  ATParse
//
//  Created by Aratech iOS on 21/12/16.
//  Copyright © 2016 AraTech. All rights reserved.
//

import Foundation
import Parse
import XCGLogger

open class ATParse {
    
    /// Realiza el login en el servidor Parse
    ///
    /// - Parameters:
    ///   - type: Tipo de login
    ///   - queue: Cola en la que ejecutar el bloque de terminación, principal por defecto
    ///   - completion: Bloque de terminación, nulo por defecto
    public static func login(_ type: LoginType, queue: DispatchQueue = .main, completion: UserLogResult? = nil) {
        
        let loginOperation = LoginOperation(type, completionQueue: queue)
        loginOperation.completion = completion
        
        let queue = OperationQueues.parse
        
        queue.addOperation(loginOperation)
    }
    
    
    /// Recupera del servidor Parse los objetos del tipo *T* especificado. El tipo T debe implementar el protocolo PFSubclassing.
    ///
    /// - Parameters:
    ///   - predicate: Predicado para la query, nulo por defecto
    ///   - completionQueue: Cola en la que ejecutar el bloque de terminación, principal por defecto.
    ///   - completion: Bloque de terminación.
    public static func fetchObjects<T: PFObject>(withPredicate predicate: NSPredicate? = nil, completionQueue: DispatchQueue = .main, completion: FetchPFObjectsResult<T>? = nil) where T: PFSubclassing {
        
        let operation: ParseClassObjectsDownloadOperation<T> = ParseClassObjectsDownloadOperation<T>(predicate: predicate, completionQueue: completionQueue)
        
        operation.completion = completion
        
        let queue = OperationQueues.parse
        
        queue.addOperation(operation)
    }
}
