//
//  ParseUserLoginOperation.swift
//  ATParse
//
//  Created by Nicolas Landa on 21/12/16.
//  Copyright © 2016 Nicolas Landa. All rights reserved.
//

import Foundation
import Parse
import ParseFacebookUtilsV4
import ParseTwitterUtils
import XCGLogger

/// Tipos de login
///
/// - normal: Login normal contra el servidor Parse, lleva asociados nombre y contraseña
/// - facebook: Login mediante Facebook, lleva asociadas las claves de los valores que se desean obtener de Facebook acerca del usuario, por defecto: `"id, email, first_name, last_name"`
/// - twitter: Login mediante Twitter
public enum LoginType {
    case normal(username: String, password: String)
    case facebook(profileInfoRequestParameters: String?)
    case twitter
}

public typealias UserLogResult = (UserError?, PFUser?)->Void

/// Operación de login, se inicializa con el tipo que se desee realizar el mismo.
class LoginOperation: Operation {
    
    /// Tipo de login
    private let type: LoginType
    
    /// Error de la operación
    var error: UserError?
    
    /// Bloque a ejecutar cuando finalice la operación
    var completion: UserLogResult?
    
    /// Cola en la que se ejecutará el bloque al término de la operación, principal por defecto
    var completionQueue: DispatchQueue
    
    ///
    ///
    /// - Parameters:
    ///   - loginType: Tipo de login que se desea realizar
    ///   - completionQueue: Cola en la que ejecutar el bloque al término de la operación, principal por defecto.
    init(_ loginType: LoginType, completionQueue: DispatchQueue = .main) {
        
        self.type = loginType
        self.completionQueue = completionQueue
        
        super.init()
        
        self.completionBlock = {
            XCGLogger.info("LoginOperation of type \(self.type) finished")
        }
    }
    
    override func main() {
        
        switch type {
        case .normal(let username, let password):
            self.login(withUserName: username, andPassword: password)
        case .facebook:
            self.facebookLogIn()
        case .twitter:
            XCGLogger.warning("Not yet implemented")
        }
    }
    
    /// Intenta logearse normalmente a través de Parse
    ///
    /// - Parameters:
    ///   - username: nombre de usuario
    ///   - password: contraseña
    func login(withUserName username: String, andPassword password: String){
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            if let error = error as? NSError {
                self.error = UserError(withCode: error.code)
                
                if self.error == .invalidUsernamePassword {
                    // Combinacion usuario/contraseña invalida
                    XCGLogger.error("The given combination \(username)/\(password) is not valid")
                }
                
            } else {
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error,user)
                }
            }
        }
    }
    
    /// Intenta logearse a través de Facebook con el token actual. De no ser posible inicia el proceso de registro a través, igualmente, de Facebook.
    ///
    /// - Parameter signUpIfLoginFails: Por defecto a *true*, indica si se desea realizar el registro a través de Facebook en caso de que el token actual no funcione.
    private func facebookLogIn(signUpIfLoginFails: Bool = true) {
        
        guard let token = FBSDKAccessToken.current() else {
            // Si no hay token guardado, al registro
            XCGLogger.info("No previously saved token, skipping to registration")
            
            if signUpIfLoginFails {
                self.facebookSignUp()
            }
            
            return
        }
        
        PFFacebookUtils.logInInBackground(with: token) { user, error in
            if let error = error as? NSError {
                XCGLogger.error("There was an error logging in: \(error)")
                self.error = UserError(withCode: error.code)
            } else {
                XCGLogger.info("User logged in through Facebook \(user)")
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error,user)
                }
            }
        }
    }
    
    /// Realiza el sign up mediante el SDK de Facebook. Crea un nuevo usuario en el servidor Parse y le añade la información almacenada en Facebook sobre dicho usuario.
    private func facebookSignUp() {
        
        // Debe hacerse en el thread principal, pues el SDK de Facebook muestra una nueva pantalla en la UI
        DispatchQueue.main.async {
            
            PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile","email"]) { (user, error) in
                
                if let error = error as? NSError {
                    XCGLogger.error("Something went wrong when logging with Facebook")
                    self.error = UserError(withCode: error.code)
                } else if let user = user {
                    
                    var requestParameters: [String:String] = [:]
                    
                    if case .facebook(let profileInfoRequestParameters) = self.type , let parameters = profileInfoRequestParameters {
                        requestParameters["fields"] = parameters
                    } else {
                        requestParameters["fields"] = "id, email, first_name, last_name"
                    }
                    
                    // Se le piden a Facebook los datos del usuario, para completar la información del registro
                    if let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: requestParameters) {
                        
                        userDetails.start(completionHandler: { (connection, result, error) in
                            if let error = error as? NSError {
                                XCGLogger.error(error.localizedDescription)
                                self.error = UserError(withCode: error.code)
                            } else {
                                if let result = result as? NSDictionary {
                                    
                                    let userId = result["id"] as! String
                                    let firstName = result["first_name"] as? String
                                    let lastName = result["last_name"] as? String
                                    let email = result["email"] as? String
                                    
                                    XCGLogger.info("Details from user with id: \(userId) successfully adquired")
                                    
                                    user.setValue(firstName, forKey: "first_name")
                                    user.setValue(lastName, forKey: "last_name")
                                    user.setValue(email, forKey: "email")
                                    
                                    user.saveInBackground { success, error in
                                        XCGLogger.info("User \(user.description) \(error) updated")
                                        if let error = error as? NSError {
                                            self.error = UserError(withCode: error.code)
                                        } else {
                                            self.error = UserError.noError()
                                        }
                                    }
                                } else {
                                    XCGLogger.error("Could not cast the response to a Dictionary")
                                    self.error = UserError(withCode: 0)
                                }
                            }
                        })
                    } else {
                        XCGLogger.error("Something occurred when creating the GraphRequest")
                        self.error = UserError(withCode: 0)
                    }
                } else {
                    // El usuario canceló el login
                    XCGLogger.info("The user cancelled the Facebok logging process")
                    self.error = .userCancelledFacebookLogin
                }
                
                if let completion = self.completion {
                    self.completionQueue.async {
                        completion(self.error,user)
                    }
                }
            }
        }
    }
}
