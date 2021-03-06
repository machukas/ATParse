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

/// Tipos de login
///
/// - normal: Login normal contra el servidor Parse, lleva asociados nombre y contraseña
/// - facebook: Login mediante Facebook, lleva asociadas las claves de los valores que se desean obtener de Facebook acerca del usuario,
///					por defecto: `"id, email, first_name, last_name, genre, age_range, picture"`
/// - twitter: Login mediante Twitter
public enum LoginType {
    case normal(username: String, password: String)
    case facebook(profileInfoRequestParameters: String?)
    case twitter
}

/// Closure al completarse el login. userInfo contiene la información del usuario recabada del servicio de login usado, i.e: Facebook.
public typealias UserLogResult = (_ error: UserError?, _ user: PFUser?, _ userInfo: [String: Any]?) -> Void

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
            NSLog("LoginOperation of type \(self.type) finished")
        }
    }
    
    override func main() {
        
        switch type {
        case .normal(let username, let password):
            self.login(withUserName: username, andPassword: password)
        case .facebook:
            self.facebookLogIn()
        case .twitter:
            NSLog("Not yet implemented")
        }
    }
    
    /// Intenta logearse normalmente a través de Parse
    ///
    /// - Parameters:
    ///   - username: nombre de usuario
    ///   - password: contraseña
    func login(withUserName username: String, andPassword password: String) {
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            if let error = error as NSError? {
                self.error = UserError(withCode: error.code)
                
                if self.error == .invalidUsernamePassword {
                    // Combinacion usuario/contraseña invalida
                    NSLog("The given combination \(username)/\(password) is not valid")
                }
                
            } else {
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error, user, nil)
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
            NSLog("No previously saved token, skipping to registration")
            
            if signUpIfLoginFails {
                self.facebookSignUp()
            }
            
            return
        }
        
        PFFacebookUtils.logInInBackground(with: token) { user, error in
            if let error = error as NSError? {
                NSLog("There was an error logging in: \(error)")
                self.error = UserError(withCode: error.code)
            } else if let user = user {
                NSLog("User logged in through Facebook \(user)")
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error, user, nil)
                }
            }
        }
    }
	
	//swiftlint:disable function_body_length
    /// Realiza el sign up mediante el SDK de Facebook. Crea un nuevo usuario en el servidor Parse y le añade la información almacenada en Facebook sobre dicho usuario.
	private func facebookSignUp() {
		
		// Debe hacerse en el thread principal, pues el SDK de Facebook muestra una nueva pantalla en la UI
		DispatchQueue.main.async {
			
			PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile", "email"]) { (user, error) in
				
				if let error = error as NSError? {
					NSLog("Something went wrong when logging with Facebook")
					self.error = UserError(withCode: error.code)
					
					self.completionQueue.async {
						self.completion?(self.error, user, nil)
					}
					
				} else if let user = user {
					
					if user.isNew { // Si el usuario es nuevo, pedir a Facebook sus datos básicos de registro
						
						var requestParameters: [String: String] = [:]
						
						if case .facebook(let profileInfoRequestParameters) = self.type, let parameters = profileInfoRequestParameters {
							requestParameters["fields"] = parameters
						} else {
							requestParameters["fields"] = "id, email, first_name, last_name, gender, picture.type(large), age_range"
						}
						
						// Se le piden a Facebook los datos del usuario, para completar la información del registro
						if let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: requestParameters) {
							
							userDetails.start(completionHandler: { (_, result, error) in
								if let error = error as NSError? {
									NSLog(error.localizedDescription)
									self.error = UserError(withCode: error.code)
									
									if error.code == 8 { // Error con la petición al Facebook Graph
										user.deleteInBackground()
										self.error = UserError.unknown
									}
									
								} else {
									if let result = result as? NSDictionary {
										
										let userId = result["id"] as? String
										
										NSLog("Details from user with id: \(userId ?? "unknown") successfully adquired")
										
										user.saveInBackground { _, error in
											if let error = error as NSError? {
												NSLog("Error updating user \(user.description): \(error)")
												self.error = UserError(withCode: error.code)
											} else {
												self.error = UserError.noError()
											}
											
											self.completionQueue.async {
												self.completion?(self.error, user, result as? [String: Any])
											}
										}
									} else {
										NSLog("Could not cast the response to a Dictionary")
										self.error = UserError(withCode: 0)
										
										self.completionQueue.async {
											self.completion?(self.error, user, nil)
										}
									}
								}
							})
						} else {
							NSLog("Something occurred when creating the GraphRequest")
							self.error = UserError(withCode: 0)
							
							self.completionQueue.async {
								self.completion?(self.error, user, nil)
							}
						}
					} else {
						// El usuario no es nuevo, hacer login
						NSLog("The user is not new, loggin in...")
						
						self.completionQueue.async {
							self.completion?(nil, user, nil)
						}
					}
				} else {
					// El usuario canceló el login
					NSLog("The user cancelled the Facebok logging process")
					self.error = .userCancelledFacebookLogin
					
					self.completionQueue.async {
						self.completion?(self.error, user, nil)
					}
				}
			}
		}
	}
	
	private func twitterLogin() {
		
	}
}
