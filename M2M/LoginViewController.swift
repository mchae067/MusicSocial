//
//  LoginViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/10/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var login_signUp_button: UIButton!
    @IBOutlet weak var switchMode_button: UIButton!
    @IBOutlet weak var signUpDescription: UILabel!
    @IBOutlet weak var signUpDescription2: UILabel!
   
    var signUpActive = true
    
    var activitiyIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    var currentUser : String = ""
    
    var passedName : String = ""
    
    @IBAction func login_signUp(sender: AnyObject) {
        
        //error checking, if invalid username or password, display alert
        if usernameText.text == "" || passwordText.text == "" {
                displayAlert("Error In Field", message: "Please enter a username and password")
            
        //else sign the user up or login, depending on the mode
        } else {
            
            //if user is in sign up mode
            if signUpActive == true {
                
                //create activity indicator (the spin circle thing when
                //user login to indicate that the system is running)
                activitiyIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
                activitiyIndicator.center = self.view.center
                activitiyIndicator.hidesWhenStopped = true
                activitiyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
                view.addSubview(activitiyIndicator)
                activitiyIndicator.startAnimating()
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                
                //create a new user
                let user = PFUser()
                user.username = usernameText.text
                user.password = passwordText.text
                
                var errorMsg = "Please Try Again Later"
                
                //tries to sign the user up
                user.signUpInBackgroundWithBlock({ (success, error) -> Void in
                    
                    //ends activity indicator
                    self.activitiyIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    //if successful
                    if error == nil {
                        //sign up successful
                        
                        let placeholderImage:UIImage = UIImage(named: "SampleProfileImage")!
                        
                        let userData = PFObject(className:"userData")
                        userData["profileImage"] = PFFile(name: "userProfileImage", data: UIImageJPEGRepresentation(placeholderImage, 0.5)!)
                        userData["friendList"] = []
                        userData["username"] = self.usernameText.text
                        userData["points"] = 0
                        userData.saveInBackgroundWithBlock {
                            (success: Bool, error: NSError?) -> Void in
                            if (success) {
                                //if user is successfully created and saved on Parse, perform segue
                                self.performSegueWithIdentifier("loginSegue", sender: self)
                                self.currentUser = self.usernameText.text!
                            } else {
                                print(error)
                            }
                        }
                        
                    //if not successful, alert the error message
                    } else {
                        if let errorString = error!.userInfo["error"] as? String {
                            errorMsg = errorString
                        }
                            self.displayAlert("Failed Sign up", message: errorMsg)
                    }
                })
            
            //log in mode
            } else {
                
                //create activity indicator (the spin circle thing when
                //user login to indicate that the system is running)
                activitiyIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
                activitiyIndicator.center = self.view.center
                activitiyIndicator.hidesWhenStopped = true
                activitiyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
                view.addSubview(activitiyIndicator)
                activitiyIndicator.startAnimating()
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                
                //attempts to log the user in
                PFUser.logInWithUsernameInBackground(usernameText.text!, password: passwordText.text!, block: { (user, error) -> Void in
                    
                    //ends activitiy indicator
                    self.activitiyIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    if user != nil {
                        //logged in, so perform segue
                        self.performSegueWithIdentifier("loginSegue", sender: self)
                        
                    } else {
                        //login unsuccessful, alert error message
                        var errorMsg = "Login failed"
                        if let errorString = error!.userInfo["error"] as? String {
                            errorMsg = errorString
                        }
                        self.displayAlert("Failed Login", message: errorMsg)
                    }
                })
            }
        }
    }
    
    
    //alert function
    @available(iOS 8.0, *)
    func displayAlert(title:String, message:String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //button for switching the mode between login and sign up
    @IBAction func switchMode(sender: AnyObject) {
        
        if (signUpActive == true) {
            
            login_signUp_button.setTitle("Login", forState: UIControlState.Normal)
            //switchMode_button.setTitle("Sign Up", forState: UIControlState.Normal)
            signUpDescription2.text = "Don't have an account?"
            //signUpDescription.text = "Login Below!"
            signUpActive = false
            
        } else {
            
            login_signUp_button.setTitle("Sign Up", forState: UIControlState.Normal)
            //switchMode_button.setTitle("Login", forState: UIControlState.Normal)
            signUpDescription2.text = "Already have an account?"
            //signUpDescription.text = "Sign Up Below!"
            signUpActive = true
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if passedName != ""  {
            currentUser = passedName
        }
        if PFUser.currentUser()?.username != nil {
            currentUser = (PFUser.currentUser()?.username)!
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        //perform segue to tabviewController if a user is already logged in
        if currentUser != "" && currentUser != "no_UsEr"{
            performSegueWithIdentifier("loginSegue", sender: self)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
