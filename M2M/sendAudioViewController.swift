//
//  sendAudioViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/11/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse

class sendAudioViewController: UIViewController {
    
    var audioFile = "String" //placeholder
    var receiver = "" //placeholder
    var recordingName = "" //placeholder, needs to be passed from prepareForSegue from audioEditor
    
    var activitiyIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sendFile() {
        
        //start activity indicator
        self.activitiyIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        self.activitiyIndicator.center = self.view.center
        self.activitiyIndicator.hidesWhenStopped = true
        self.activitiyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        self.view.addSubview(self.activitiyIndicator)
        self.activitiyIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        //let audioFile : NSData // dummy file
        
        let testClass = PFObject(className: "\(receiver)_audioFiles") //need to change
        testClass["audioName"] = recordingName //need to change
        //testClass["audioFile"] = audioFile //need to change
        testClass["ownerUserName"] = (PFUser.currentUser()?.username)!
        testClass["author"] = receiver
        testClass.saveInBackgroundWithBlock({ (success, error) -> Void in
            if error != nil {
                print(error)
                print("didnt save!!")
                
                //ends activity indicator
                self.activitiyIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                
                let alert = UIAlertController(title: "Failed",
                    message: "Unable to save audio file",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: {action in
                }))
                
                self.presentViewController(alert, animated:true, completion:nil)
                
            } else {
                //saved to Parse!
                print("saved to Parse")
                //ends activity indicator
                self.activitiyIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                self.createNotification(self.receiver)
            }
        })
    }
    
    func createNotification(username:String) {
        let audioToSend = PFObject(className: "sentAudioFiles")
        
        // audioToSend["audio"] = PFFile(name: "audio.mp3", contentsAtPath: audioFile)
        audioToSend["senderUsername"] = PFUser.currentUser()?.username
        audioToSend["receiverUsername"] = receiver
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
