//
//  ATParseObject.swift
//  ATParse
//
//  Created by Nicolas Landa on 4/1/17.
//  Copyright © 2017 Nicolas Landa. All rights reserved.
//

import UIKit
import Parse
import XCGLogger

/// Provee de operaciones basicas genéricas.
open class ATParseObject: PFObject {
    
    /// Recupera una propiedad de tipo `T` del PFObject
    ///
    /// - Parameter key: La clave del valor a recuperar
    /// - Returns: El valor de la propiedad recuperada
    public func property<T>(forKey key: String) -> T? {
        let value = self.object(forKey: key) as? T
        if value == nil {
            XCGLogger.error(self.errorLogMessage(key: key))
        }
        return value
    }
    
    // MARK:- Private
    
    /// Compone el mensaje de log para cuando se pide una propiedad cuya clave es inexistente en el PFObject
    ///
    /// - Parameter key: La clave que no se encuentra
    /// - Returns: El mensaje de error
    private func errorLogMessage(key: String) -> String {
        return "No property found in \(parseClassName).\(self.objectId) with key=\(key)"
    }
}
