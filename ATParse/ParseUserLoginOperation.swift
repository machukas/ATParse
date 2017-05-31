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

/// Tipos de login
///
/// - normal: Login normal contra el servidor Parse, lleva asociados nombre y contraseña
/// - facebook: Login mediante Facebook, lleva asociadas las claves de los valores que se desean obtener de Facebook acerca del usuario, por defecto: `"id, email, first_name, last_name, genre, age_range, picture"`
/// - twitter: Login mediante Twitter
public enum LoginType {
    case normal(username: String, password: String)
    case facebook(profileInfoRequestParameters: String?)
    case twitter
}

/// Closure al completarse el login. userInfo contiene la información del usuario recabada del servicio de login usado, i.e: Facebook.
public typealias UserLogResult = (_ error: UserError?, _ user: PFUser?, _ userInfo: [String:Any]?)->Void

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
            log.info("LoginOperation of type \(self.type) finished")
        }
    }
    
    override func main() {
        
        switch type {
        case .normal(let username, let password):
            self.login(withUserName: username, andPassword: password)
        case .facebook:
            self.facebookLogIn()
        case .twitter:
            log.warning("Not yet implemented")
        }
    }
    
    /// Intenta logearse normalmente a través de Parse
    ///
    /// - Parameters:
    ///   - username: nombre de usuario
    ///   - password: contraseña
    func login(withUserName username: String, andPassword password: String){
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            if let error = error as NSError? {
                self.error = UserError(withCode: error.code)
                
                if self.error == .invalidUsernamePassword {
                    // Combinacion usuario/contraseña invalida
                    log.error("The given combination \(username)/\(password) is not valid")
                }
                
            } else {
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error,user, nil)
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
            log.info("No previously saved token, skipping to registration")
            
            if signUpIfLoginFails {
                self.facebookSignUp()
            }
            
            return
        }
        
        PFFacebookUtils.logInInBackground(with: token) { user, error in
            if let error = error as NSError? {
                log.error("There was an error logging in: \(error)")
                self.error = UserError(withCode: error.code)
            } else if let user = user {
                log.info("User logged in through Facebook \(user)")
                self.error = UserError.noError()
            }
            
            if let completion = self.completion {
                self.completionQueue.async {
                    completion(self.error,user, nil)
                }
            }
        }
    }
    
    /// Realiza el sign up mediante el SDK de Facebook. Crea un nuevo usuario en el servidor Parse y le añade la información almacenada en Facebook sobre dicho usuario.
	private func facebookSignUp() {
		
		// Debe hacerse en el thread principal, pues el SDK de Facebook muestra una nueva pantalla en la UI
		DispatchQueue.main.async {
			
			PFFacebookUtils.logInInBackground(withReadPermissions: ["public_profile","email"]) { (user, error) in
				
				if let error = error as NSError? {
					log.error("Something went wrong when logging with Facebook")
					self.error = UserError(withCode: error.code)
				} else if let user = user {
					
					if user.isNew { // Si el usuario es nuevo, pedir a Facebook sus datos básicos de registro
						
						var requestParameters: [String:String] = [:]
						
						if case .facebook(let profileInfoRequestParameters) = self.type , let parameters = profileInfoRequestParameters {
							requestParameters["fields"] = parameters
						} else {
							requestParameters["fields"] = "id, email, first_name, last_name, gender, picture.type(large), age_range"
						}
						
						// Se le piden a Facebook los datos del usuario, para completar la información del registro
						if let userDetails = FBSDKGraphRequest(graphPath: "me", parameters: requestParameters) {
							
							userDetails.start(completionHandler: { (connection, result, error) in
								if let error = error as NSError? {
									log.error(error.localizedDescription)
									self.error = UserError(withCode: error.code)
									
									if error.code == 8 { // Error con la petición al Facebook Graph
										user.deleteInBackground()
										self.error = UserError.unknown
									}
									
								} else {
									if let result = result as? NSDictionary {
										
										let userId = result["id"] as? String
										
										if let firstName = result["first_name"] as? String {
											user.setValue(firstName, forKey: "first_name")
										}
										
										if let lastName = result["last_name"] as? String {
											user.setValue(lastName, forKey: "last_name")
										}
										
										if let genre = result["gender"] as? String {
											user.setValue(genre=="male" ? "man" : "woman", forKey: "sex")
										}
										
										if let ageRange = result["age_range"] as? String {
											user.setValue(ageRange, forKey: "age_range")
										}
										
										if let email = result["email"] as? String {
											user.setValue(email, forKey: "email")
										}
										
										if let pictureDictionary = result["picture"] as? [String:Any],
											let pictureData = pictureDictionary["data"] as? [String:Any],
											let pictureURL = pictureData["url"] as? String {
											
											user.setValue(pictureURL, forKey: "icon")
										}
										
										log.info("Details from user with id: \(userId ?? "unknown") successfully adquired")
										
										user.saveInBackground { success, error in
											if let error = error as NSError? {
												log.error("Error updating user \(user.description): \(error)")
												self.error = UserError(withCode: error.code)
											} else {
												self.error = UserError.noError()
											}
											
											self.completionQueue.async {
												self.completion?(self.error,user, result as? [String:Any])
											}
										}
									} else {
										log.error("Could not cast the response to a Dictionary")
										self.error = UserError(withCode: 0)
										
										self.completionQueue.async {
											self.completion?(self.error,user, nil)
										}
									}
								}
							})
						} else {
							log.error("Something occurred when creating the GraphRequest")
							self.error = UserError(withCode: 0)
							
							self.completionQueue.async {
								self.completion?(self.error,user, nil)
							}
						}
					}
				} else {
					// El usuario canceló el login
					log.info("The user cancelled the Facebok logging process")
					self.error = .userCancelledFacebookLogin
					
					self.completionQueue.async {
						self.completion?(self.error,user, nil)
					}
				}
			}
		}
	}
	
	private func twitterLogin() {
		
	}
}
