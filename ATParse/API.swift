//
//  API.swift
//  ATParse
//
//  Created by Nicolas Landa on 21/12/16.
//  Copyright © 2016 Nicolas Landa. All rights reserved.
//

import Foundation
import Parse
import XCGLogger

open class ATParse {
    
    /// Política de cache
    private let cachePolicy: PFCachePolicy
    
    ///
    /// - Parameter cachePolicy: Política de cache a aplicar en las peticiones
    public init(withCachePolicy cachePolicy: PFCachePolicy) {
        self.cachePolicy = cachePolicy
    }
    
    /// Realiza el login en el servidor Parse
    ///
    /// - Parameters:
    ///   - type: Tipo de login
    ///   - queue: Cola en la que ejecutar el bloque de terminación, principal por defecto
    ///   - completion: Bloque de terminación, nulo por defecto
    public func login(_ type: LoginType, queue: DispatchQueue = .main, completion: UserLogResult? = nil) {
        
        let loginOperation = LoginOperation(type, completionQueue: queue)
        loginOperation.completion = completion
        
        let queue = OperationQueues.parse
        
        queue.addOperation(loginOperation)
    }
    
    
    /// Recupera del servidor Parse los objetos del tipo *T* especificado. El tipo T debe implementar el protocolo PFSubclassing.
    ///
    /// - Parameters:
    ///   - predicate: Predicado para la query, nulo por defecto
    ///   - includedKeys: Claves a incluir en la búsqueda para obtener los objetos relacionados, ninguna por defecto
    ///   - completionQueue: Cola en la que ejecutar el bloque de terminación, principal por defecto
    ///   - completion: Bloque de terminación, nulo por defecto
    /// - Returns: Centinela para que el compilador pueda inferir el tipo T, NO USAR
    public func fetchObjects<T: PFObject>(withPredicate predicate: NSPredicate? = nil, includingKeys includedKeys: [String] = [], completionQueue: DispatchQueue = .main, completion: FetchPFObjectsResult<T>? = nil)  -> T? where T: PFSubclassing {
        
        let operation: ParseClassObjectsDownloadOperation<T> = ParseClassObjectsDownloadOperation<T>(predicate: predicate, includingKeys: includedKeys, cachePolicy: self.cachePolicy , completionQueue: completionQueue)
        
        operation.completion = completion
        
        let queue = OperationQueues.parse
        
        queue.addOperation(operation)
        
        return operation.objects?.first
    }
}
