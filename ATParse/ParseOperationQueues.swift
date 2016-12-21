//
//  ParseOperationQueues.swift
//  ATParse
//
//  Created by Aratech iOS on 21/12/16.
//  Copyright © 2016 AraTech. All rights reserved.
//

import Foundation
import XCGLogger

/// Colas disponibles para las operaciones:
struct OperationQueues {
    /// Cola para las operaciones relacionadas con el servidor Parse
    static var parse: OperationQueue {
        let queue = OperationQueue()
        queue.name = "ParseOperationsQueue"
        XCGLogger.info("Created \(queue.description) operation queue")
        return queue
    }
}
