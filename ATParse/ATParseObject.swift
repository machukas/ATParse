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

/// Un tipo Parse con una representación textual personalizada. Este protocolo es necesario pues la variable `description` ya es usada por `PFObject`
public protocol ParseCustomStringConvertible {
    /// Representación textual del objeto `Parse`. Por defecto valor de la clave `name` del objeto
    var itemDescription: String { get }
}

public extension ParseCustomStringConvertible where Self: ATParseObject {
    
    public var itemDescription: String {
        return self.property(forKey: "name") ?? ""
    }
}

/// Provee de operaciones básicas genéricas.
open class ATParseObject: PFObject, ParseCustomStringConvertible {
    
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
        return "No property found in \(parseClassName).\(self.objectId!) with key=\(key)"
    }
}
