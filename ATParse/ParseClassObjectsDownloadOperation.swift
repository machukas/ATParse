//
//  ParseClassObjectsDownloadOperation.swift
//  ATParse
//
//  Created by Aratech iOS on 21/12/16.
//  Copyright © 2016 AraTech. All rights reserved.
//

import Foundation
import Parse
import XCGLogger

public typealias FetchPFObjectsResult<T: PFObject> = (ParseError?, [T]?)->Void

/// Operación para la descarga de los objetos de una clase en un servidor Parse
class ParseClassObjectsDownloadOperation<T: PFObject>: Operation where T: PFSubclassing {
    
    /// Predicado de la query
    let predicate: NSPredicate?
    
    /// Objectos recabados
    var objects: [T]?
    
    /// Error de la operación
    var error: ParseError?
    
    /// Bloque a ejecutar cuando finalice la operación
    var completion: FetchPFObjectsResult<T>?
    
    /// Cola en la que se ejecutará el bloque al término de la operación, principal por defecto
    var completionQueue: DispatchQueue
    
    ///
    ///
    /// - Parameters:
    ///   - predicate: Predicado para la query, nulo por defecto.
    ///   - completionQueue: Cola en la que ejecutar el bloque al término de la operación, principal por defecto.
    init(predicate: NSPredicate? = nil, completionQueue: DispatchQueue = .main) {
        self.predicate = predicate
        self.completionQueue = completionQueue
        
        super.init()
        
        self.completionBlock = {
            XCGLogger.info("ParseClassObjectsDownloadOperation of type \(T.parseClassName()) finished")
        }
    }
    
    override open func main() {
        
        if self.isCancelled {
            return
        }
        
        let query: PFQuery<T> = PFQuery(className: T.parseClassName(), predicate: predicate)
        
        if self.isCancelled {
            return
        }
        
        // Busqueda
        do {
            self.objects = try query.findObjects()
            self.error = ObjectError.noError()
        } catch let error as NSError {
            XCGLogger.error(error.userInfo)
            self.error = ObjectError(withCode: error.code)
        }
        
        if self.isCancelled {
            return
        }
        
        // Si hay bloque de terminación
        if let completion = self.completion {
            self.completionQueue.async {
                completion(self.error, self.objects)
            }
        }
    }
}
