//
//  sendToFriendsViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/18/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class sendToFriendsViewController: UIViewController {
    
    var friendsList : [String] = []
    var selectedFriends : [Int] = []
    var selectedFriendsName : [String] = []
    
    var recordingName = "test_test"
    //var url : NSURL!
    
    var testAudioFile : PFFile!
    
    var activitiyIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        
        let query = PFQuery(className: "userData")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                if let friends = object!["friendList"] as? NSArray {
                    for friend in friends {
                        self.friendsList.append(friend as! String)
                    }
                }
            } else {
                print(error)
            }
            self.tableView.reloadData()
        }

        //************************** TEST ****************************************
        let testQuery = PFQuery(className: "a123_audioFiles")
        testQuery.whereKey("audioName", equalTo: "test123")
        testQuery.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                self.testAudioFile = object!["audioFile"] as! PFFile
                
            } else {
                print(error)
            }
        }
        //************************** TEST ****************************************

        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendAudio(sender: AnyObject) {
        print(selectedFriends)
        sendFile()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsList.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("sendToFriendsCell")! as UITableViewCell;
        
        cell.textLabel?.text = friendsList[indexPath.row]
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var alreadyChecked = false
        let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        for cellIndex in selectedFriends {
            if cellIndex == indexPath.row {
                alreadyChecked = true
            }
        }
        if alreadyChecked {
            selectedCell.accessoryType = UITableViewCellAccessoryType.None
            for var i=0; i<selectedFriends.count; i++ {
                if selectedFriends[i] == indexPath.row {
                    selectedFriends.removeAtIndex(i)
                }
            }
        } else {
            selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
            selectedFriends.append(indexPath.row)
        }
    }
    
    func sendFile() {
        
        for selected in selectedFriends {
            selectedFriendsName.append(friendsList[selected])
        }
        
        print(selectedFriendsName)
        
        
        //start activity indicator
        self.activitiyIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        self.activitiyIndicator.center = self.view.center
        self.activitiyIndicator.hidesWhenStopped = true
        self.activitiyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        self.view.addSubview(self.activitiyIndicator)
        self.activitiyIndicator.startAnimating()
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        
        //let audioFile : NSData
        
        //testAudioFile = PFFile(name: recordingName, data: NSData(contentsOfURL: self.url!)!)
        
        for friend in selectedFriendsName {
            let newAudio = PFObject(className: "\(friend)_audioFiles") //need to change
            newAudio["audioName"] = recordingName //need to change
            newAudio["audioFile"] = testAudioFile
            newAudio["author"] = (PFUser.currentUser()?.username)!
            newAudio.saveInBackgroundWithBlock({ (success, error) -> Void in
                if error != nil {
                    print("didnt save!!")
                    
                    //ends activity indicator
                    self.activitiyIndicator.stopAnimating()
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    
                    let alert = UIAlertController(title: "Failed",
                        message: "Unable to send audio file",
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
                    if friend == self.selectedFriendsName[self.selectedFriendsName.count-1] {
                        self.createNotification()
                    }
                }
            })
        }
        let addPoints = PFQuery(className: "userData")
        addPoints.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        addPoints.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                var point = object!["points"] as! Int
                point = point + (10 * self.selectedFriends.count)
                print(point)
                object!["points"] = point
                object?.saveInBackground()
            } else {
                print(error)
            }
        }        
    }
    
    func createNotification() {
        for friend in selectedFriendsName {
            let audioToSend = PFObject(className: "sentAudioFiles")
            audioToSend["senderUsername"] = (PFUser.currentUser()?.username)!
            audioToSend["receiverUsername"] = friend
            let postACL = PFACL(user: PFUser.currentUser()!)
            postACL.setPublicWriteAccess(true)
            postACL.setPublicReadAccess(true)
            audioToSend.ACL = postACL
            //audioToSend["notified"] = false
            audioToSend.saveInBackgroundWithBlock { (success, error) -> Void in
                if error == nil {
                    print("success")
                    if friend == self.selectedFriendsName[self.selectedFriendsName.count-1] {
                        self.performSegueWithIdentifier("finishedSendingSegue", sender: self)
                    }
                } else {
                    print(error)
                }
            }
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
