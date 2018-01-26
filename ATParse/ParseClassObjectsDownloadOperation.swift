//
//  ParseClassObjectsDownloadOperation.swift
//  ATParse
//
//  Created by Nicolas Landa on 21/12/16.
//  Copyright © 2016 Nicolas Landa. All rights reserved.
//

import Foundation
import Parse

public typealias FetchPFObjectsResult<T: PFObject> = (ParseError?, [T]?) -> Void
public typealias OrderBy = (direction: OrderDirection, key: String)

public enum OrderDirection {
	case ascending
	case descending
}

/// Tamaño de página por defecto
public let defaultPageSize: Int = 100
/// Tamaño máximo de página
public let maxPageSize: Int = 1000

/// Operación para la descarga de los objetos de una clase en un servidor Parse
open class ParseClassObjectsDownloadOperation<T: PFObject>: Operation where T: PFSubclassing {
	
    /// PFQuery
    let query: PFQuery<T>
	
	/// Número de elementos máximos por petición, `100` por defecto, `1000` máximo. Si 0
	var pageSize: Int
	
	/// Página pedida. Si la página es 2, se recabarán los segundos `pageSize` elementos. Si se desean todos los objetos, pasar `0`.
	let page: Int
	
	/// Ordenación de los resultados de la query
	let orderBy: [OrderBy]
    
    /// Si hay un resultado de la operación en cache
    public var hasCachedResult: Bool {
        return self.query.hasCachedResult
    }
    
    /// Objectos recabados
    public var objects: [T]?
    
    /// Error de la operación
    var error: ParseError?
    
    /// Bloque a ejecutar cuando finalice la operación
    public var completion: FetchPFObjectsResult<T>?
    
    /// Cola en la que se ejecutará el bloque al término de la operación, principal por defecto
    var completionQueue: DispatchQueue
    
    ///
    ///
    /// - Parameters:
    ///   - query:				Consulta para la petición, nulo por defecto.
    ///   - includedKeys:		Claves a incluir en la búsqueda para obtener los objetos relacionados
    ///   - cachePolicy:		Política de cache, ignorar cache por defecto
	///   - pageSize:			Número de elementos máximos por petición, `100` por defecto
	///   - page:					Página que se desea obtener. Si la página es 2, se recabarán los segundos `pageSize` elementos. `1` por defecto. Si se desean todos los objetos, pasar `0`.
	///   - orderBy:				Ordenación de los resultados de la query
    ///   - completionQueue:	Cola en la que ejecutar el bloque al término de la operación, principal por defecto
	public init(query: PFQuery<T>,
				includingKeys includedKeys: [String] = [],
				cachePolicy: PFCachePolicy = .ignoreCache,
				pageSize: Int = defaultPageSize,
				page: Int = 1,
				orderBy: [OrderBy] = [],
				completionQueue: DispatchQueue = .main) {

		self.completionQueue = completionQueue
        
        self.query = query
        
        self.query.includeKeys(includedKeys)
        
        self.query.cachePolicy = cachePolicy
		
		self.page = page
		
		self.pageSize = page == 0 ? maxPageSize : pageSize
		
		self.orderBy = orderBy
		
        super.init()
        
        self.completionBlock = {
            NSLog("ParseClassObjectsDownloadOperation of type \(T.parseClassName()) finished")
        }
    }

    override open func main() {
        
        if self.isCancelled {
            return
        }
        
        // Busqueda
        do {
			
			var numberOfCalls: Int = 1
			
			// Comprobar cuantos objetos se desean
			if self.page == 0 {
	
				// Todos los objetos, primero habrá que contar cuantos hay
				let count = query.countObjects(nil)
				
				if count > maxPageSize {
					// Hay que hacer varias llamadas, pues hay mas objectos que el máximo permitido por petición
					numberOfCalls = (count / maxPageSize) + (((count % maxPageSize)==0) ? 0 : 1)
				} else {
					// En una única llamada caben todos
					self.pageSize = count
				}
				
			} else {
				
				// Una página en concreto
				self.query.skip = self.pageSize * (self.page-1)
			}
			
			// Límite de elementos por petición
			self.query.limit = self.pageSize
			
			// Ordenación
			for orderBy in self.orderBy {
				switch orderBy.direction {
				case .ascending:
					self.query.addAscendingOrder(orderBy.key)
				case .descending:
					self.query.addDescendingOrder(orderBy.key)
				}
			}
			
			self.objects = []
			
			for page in 1...numberOfCalls {
				self.objects?.append(contentsOf: try query.findObjects())
				
				self.query.skip = self.pageSize * page
			}
			
            self.error = ObjectError.noError()
			
        } catch let error as NSError {
            NSLog("\(error.userInfo)")
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
