//
//  ViewFriendProfileViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/10/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class ViewFriendProfileViewController: UIViewController {

    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var userPoints: UILabel!
    @IBOutlet weak var userNumberOfFriends: UILabel!
    
    var passedName = ""
    var isFollowing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if passedName != "" {
            username.text = self.passedName     //passed username from prepareForSegue
        }
        
        // load profileImage from query from parse
        let query = PFQuery(className: "userData")
        query.whereKey("username", equalTo: username.text!)
        
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                self.userPoints.text = String(object!["points"])
                self.userNumberOfFriends.text = String(object!["friendList"].count)
                
                //fetch image from parse
                let image = PFImageView()
                image.file = object!["profileImage"] as? PFFile
                image.loadInBackground({ (photo, error) -> Void in
                    if error == nil {
                        self.userProfileImage.image = photo!
                        self.userProfileImage.layer.borderWidth = 1
                        self.userProfileImage.layer.masksToBounds = false
                        self.userProfileImage.layer.borderColor = UIColor.blackColor().CGColor
                        self.userProfileImage.layer.cornerRadius = self.userProfileImage.frame.height/2
                        self.userProfileImage.clipsToBounds = true
                    } else {
                        print(error)
                    }
                })
            } else {
                print(error)
            }
        }
        
        // if username exists in currentUser's friendList, set isFollowing to true
        let query2 = PFQuery(className: "userData")
        query2.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        
        query2.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in

            if let friends = object!["friendList"] as? NSArray {
                for friend in friends {
                    if friend as? String == self.username.text {
                        self.isFollowing = true
                    }
                }
                // set the button title
                if self.isFollowing {
                    self.addFriendButton.setTitle("Unfriend", forState: .Normal)
                } else {
                    self.addFriendButton.setTitle("Friend", forState: .Normal)
                }
            }
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var addFriendButton: UIButton!
    
    @IBAction func addFriend(sender: AnyObject) {
        
        let query = PFQuery(className: "userData")
        query.whereKey("username", equalTo: (PFUser.currentUser()?.username!)!)
        
        
        if addFriendButton.titleLabel!.text == "Unfriend" {
            
            // the following query remove the selected user from current user's friendlist
            query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
                if error == nil {
                    object?.removeObjectsInArray([self.username.text!], forKey: "friendList")
                    object?.saveInBackground()
                } else {
                    print(error)
                }
            }
            addFriendButton.setTitle("Friend", forState: .Normal)
            isFollowing = false
            
        } else {
            
            // the following query add the selected user to current user's friendlist
            query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
                if error == nil {
                    object?.addObject(self.username.text!, forKey: "friendList")
                    object?.saveInBackground()
                } else {
                    print(error)
                }
            }
            addFriendButton.setTitle("Unfriend", forState: .Normal)
            isFollowing = true
        }
    }
    /*
    override func viewWillAppear(animated: Bool) {
        let nav = self.navigationController?.navigationBar
        nav?.barTintColor = UIColor(red: 52.0/255.0, green: 152.0/255.0, blue: 219.0/255.0, alpha: 1.0)
    }*/
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
