
import CoreData

class Test: NSManagedObject {
	
}

class Test2: NSManagedObject {
	
}





//
//  ATSyncEngine.swift
//  ATParse
//
//  Created by Aratech iOS on 29/5/17.
//  Copyright © 2017 AraTech. All rights reserved.
//

import Parse
import CoreData

protocol ParseFetchRequestInfoProvider {
	var includedKeys: [String] { get }
}

open class ATSyncEngine {
	
	public static var persistentContainer: NSPersistentContainer = {
		
		let container = NSPersistentContainer(name: "ATParse")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	public class func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

}

//
//	/// Contexto en el que sincronizar
//	private let context: NSManagedObjectContext
//	
//	/// Clases registradas para su sincronización
//	private var registeredClasses: [T] = []
//	
//	// MARK:- Init
//	
//	public init(inContext context: NSManagedObjectContext) {
//		self.context = context
//	}
//	
//	// MARK:- Private
//	
//	private func mostRecentUpdatedAtDate(forClass classToCheck: NSManagedObject.Type) -> Date? {
//		var date: Date?
//		let request = classToCheck.fetchRequest()
//		request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
//		request.fetchLimit = 1
//		if let result = try? self.context.fetch(request) {
//			if let lastUpdatedDate = result.last as? NSDate {
//				date = lastUpdatedDate as Date
//			}
//		} else {
//			NSLog("")
//		}
//		return date
//	}
//	
//	private func createDownloadOperation(forClass downloadableClass: T) -> Operation? {
//		if let entityName = downloadableClass.entity.name {
//			let parseObject = PFObject(className: entityName)
//			let query = PFQuery(className: entityName)
//			
//			query.findObjectsInBackground(block: { (objects, error) in
//				print("")
//			})
//			
//			NSManagedObject().entity.attributesByName
//		}
//		
//	}
//	
//	// MARK:- API
//	
//	/// Registra la clase dada para su sincronización
//	///
//	/// - Parameter classToSync: Clase a sincronizar
//	public func registerClassForSync(_ classToSync: T) {
//		if !self.registeredClasses.contains(where: { classToSync == $0 }) {
//			self.registeredClasses.append(classToSync)
//		} else {
//			NSLog("Unable to register class \(classToSync) as it is already registered")
//		}
//	}
//	
//	public func downloadDataForRegisteredObjects(useUpdatedAtDate: Bool = true) {
//		var operations: [Operation] = []
//		
//		for registeredClass in self .registeredClasses {
//			operations.append(self.createDownloadOperation(forClass: registeredClass))
//		}
//		
//		let queue = OperationQueues.parse
//		
//		queue.addOperation(operation)
//		
//		if !async {
//			queue.waitUntilAllOperationsAreFinished()
//		}
//		
//		return operation.objects?.first
//	}
//}
