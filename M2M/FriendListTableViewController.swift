//
//  FriendListTableViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/10/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class FriendListTableViewController: UITableViewController {
    
    //var usernames : [String] = []
    //var userIds : [String] = []
    var friendsList : [String] = []
    var friendsImageFile : [String:PFFile] = [:]
    var friendsImage : [String:UIImage] = [:]
    
    
    var selectedUser = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //tableView.reloadData()

        //pull to refresh
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        //the following query attempts to store current user's friendlist and present it to table view
        let query = PFQuery(className: "userData")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.getFirstObjectInBackgroundWithBlock ({ (object, error) -> Void in
            if error == nil {
                if let friends = object!["friendList"] as? NSArray {
                    for friend in friends {
                        self.friendsList.append(friend as! String)
                    }
                }
            } else {
                print(error)
            }
            self.friendsList.sortInPlace { (element1, element2) -> Bool in
                return element1 < element2
            }
            self.populateImageFile()
        })
        
        
        //populateImageData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func populateImageFile() {
        let query = PFQuery(className: "userData")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                for object in objects! {
                    let username = object["username"] as! String
                    
                    if self.friendsList.contains(username) {
                        self.friendsImageFile[username] = object["profileImage"] as? PFFile
                    }
                    
                }
            } else {
                print(error)
            }
            self.populateImageData()
        }
    }
    
    func populateImageData() {
        let image = PFImageView()
        var count = 1
        
        for friend in friendsList {
            image.file = friendsImageFile[friend]
            image.loadInBackground({ (photo, error) -> Void in
                if error == nil {
                    self.friendsImage[friend] = photo
                } else {
                    print(error)
                }
                if count == self.friendsList.count {
                    self.tableView.reloadData()
                }
                count++
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return friendsList.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friendsListCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = friendsList[indexPath.row]
        
        //place holder image
        let cellImage : UIImage = UIImage(named: "SampleProfileImage.png")!
        
        if friendsImage[friendsList[indexPath.row]] != nil {
            cell.imageView?.image = friendsImage[friendsList[indexPath.row]]
            //cell.imageView?.layer.borderWidth = 1
            //cell.imageView?.layer.masksToBounds = false
            //cell.imageView?.layer.borderColor = UIColor.blackColor().CGColor
            //cell.imageView?.layer.cornerRadius = cell.frame.height/2
            //cell.imageView?.clipsToBounds = true
        } else {
            cell.imageView?.image = cellImage
        }
        
        //print("here")
        return cell
    }
    
    func doSomethingAtClosure() {
        self.tableView.reloadData()
    
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.selectedUser = friendsList[indexPath.row]
        performSegueWithIdentifier("viewFriendProfileSegue", sender: self)
    }
    
    //pass selected user information to the next view
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "viewFriendProfileSegue"){
            
            let svc = segue.destinationViewController as! ViewFriendProfileViewController;
            svc.passedName = self.selectedUser;
            svc.isFollowing = true
        }
    }
    
    //pull to refresh function
    func refresh(sender: AnyObject) {
        
        //clear the friend list to repopulate it
        friendsList = []
        
        //repopulate the new friendlist, there's definitely a more efficient way to do this, but i'm too lazy...
        let query = PFQuery(className: "userData")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.getFirstObjectInBackgroundWithBlock ({ (object, error) -> Void in
            if error == nil {
                if let friends = object!["friendList"] as? NSArray {
                    for friend in friends {
                        self.friendsList.append(friend as! String)
                    }
                }
            } else {
                print(error)
            }
            //reload the tableview with the new friendlist
            self.tableView.reloadData()
        })
        
        self.refreshControl?.endRefreshing()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
