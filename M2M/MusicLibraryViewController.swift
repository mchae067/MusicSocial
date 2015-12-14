//
//  MusicLibraryViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/10/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import AVFoundation

class MusicLibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate{
    
    var player:AVAudioPlayer!
    var refreshControl:UIRefreshControl!
    var selectedFileIndexRow1 : Int = -1
    var selectedFileIndexRow2 : Int = -1
    var selectedFileIndexPath : NSIndexPath!
    var previouslySelectedFileIndexPath1 : NSIndexPath!
    var previouslySelectedFileIndexPath2 : NSIndexPath!
    var currentCount = 0

    var currentCategory = 0

    var justFromLibrary = true
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addFileButton: UIBarButtonItem!
    
    var data : [String] = []
    var data0 : [String] = []
    var data1 : [String] = []
    
    var audioFiles0 : [PFFile] = []
    var audioFiles1 : [PFFile] = []
    var audioData : [NSData] = []
    var newFiles : Int = 0
    var point : Int = 0
    
    var fromEditor = false
    var tempFilename1 = ""
    var tempFilename2 = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !fromEditor {
            let tabArray = self.tabBarController?.tabBar.items as NSArray!
            let tabItem = tabArray.objectAtIndex(1) as! UITabBarItem
            tabItem.badgeValue = nil
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                for object in objects!{
                    if object["author"] as! String == (PFUser.currentUser()?.username)! {
                        self.data1.append(String(object["audioName"]))
                        let file = object["audioFile"] as! PFFile
                        self.audioFiles1.append(file)
                    } else {
                        self.data0.append(String(object["audioName"]))
                        let file = object["audioFile"] as! PFFile
                        self.audioFiles0.append(file)
                    }
                }
            } else {
                print(error)
            }
        }
        
        let deleteQuery = PFQuery(className: "sentAudioFiles")
        deleteQuery.whereKey("receiverUsername", equalTo: (PFUser.currentUser()?.username)!)
        deleteQuery.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                for object in objects!{
                    //object["notified"] = true
                    object.deleteInBackground()
                }
            } else {
                print(error)
            }
        }

        let addPoints = PFQuery(className: "userData")
        addPoints.whereKey("username", equalTo: (PFUser.currentUser()?.username)!)
        addPoints.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                self.point = object!["points"] as! Int
                self.point = self.point + (5 * self.newFiles)
                object!["points"] = self.point
                object?.saveInBackground()
            } else {
                print(error)
            }
        }
        
        if fromEditor
        {
            self.navigationItem.rightBarButtonItem = self.addFileButton
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("musicLibraryCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = data[indexPath.row]
        //let image = UIImage(named: "FriendListIcon")
        //cell.imageView?.image = image
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // if segued to library from editor, allow selecting function
        if fromEditor {
            let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
            if previouslySelectedFileIndexPath1 == nil && previouslySelectedFileIndexPath2 == nil {
                previouslySelectedFileIndexPath1 = indexPath
                previouslySelectedFileIndexPath2 = indexPath

            } else {
                if currentCount == 1 {
                    let temp = previouslySelectedFileIndexPath1
                    previouslySelectedFileIndexPath1 = selectedFileIndexPath
                    previouslySelectedFileIndexPath2 = temp
                }
                
                if currentCount == 2 {
                    previouslySelectedFileIndexPath2 = previouslySelectedFileIndexPath1
                    previouslySelectedFileIndexPath1 = selectedFileIndexPath
                    let previouslySelectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(previouslySelectedFileIndexPath2)!
                    previouslySelectedCell.accessoryType = UITableViewCellAccessoryType.None
                currentCount--
                }
            }
            
            selectedFileIndexPath = indexPath
            selectedFileIndexRow1 = indexPath.row
            selectedFileIndexRow2 = previouslySelectedFileIndexPath1.row
            
            selectedCell.accessoryType = UITableViewCellAccessoryType.Checkmark
            currentCount++
            //importAudio(self)
        }

        //play audio at selected cell
        play(indexPath.row)
    }
    
    //Slide to delete. Need permission from Parse to implement.
    /*func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            print((PFUser.currentUser()?.username)!)
            var temp : String = ""
            if currentCategory == 0 {
                temp = data0[indexPath.row]
            } else {
                temp = data1[indexPath.row]
            }
        }
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        if currentCategory == 0 {
            data0.removeAtIndex(indexPath.row)
        } else {
            data1.removeAtIndex(indexPath.row)
        }
    }*/
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let control = UISegmentedControl(items: ["Received Recordings","Your Recordings"])
        control.addTarget(self, action: "valueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        if(section == 0){
            return control;
        }
        return nil;
    }
    
    func play(index:Int) {
        
        if currentCategory == 0 {
            audioFiles0[index].getDataInBackgroundWithBlock { (audioData: NSData?, error: NSError?) -> Void in
                do {
                    try self.player = AVAudioPlayer(data: audioData!, fileTypeHint: AVFileTypeAppleM4A)
                    self.player.prepareToPlay()
                    self.player.volume = 1.0
                    self.player.play()
                }
                catch let error as NSError {
                    self.player = nil
                    print(error.localizedDescription)
                }
            }
        } else {
            audioFiles1[index].getDataInBackgroundWithBlock { (audioData: NSData?, error: NSError?) -> Void in
                do {
                    try self.player = AVAudioPlayer(data: audioData!, fileTypeHint: AVFileTypeAppleM4A)
                    self.player.prepareToPlay()
                    self.player.volume = 1.0
                    self.player.play()
                }
                catch let error as NSError {
                    self.player = nil
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func importAudio(sender: AnyObject) {
        //var controller: UINavigationController
        //controller = self.storyboard?.instantiateViewControllerWithIdentifier("NavigationVCIdentifierFromStoryboard") as! UINavigationController
        //controller = self.storyboard?.
        //controller.yourTableViewArray = localArrayValue
        //navigationController?.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "libraryToEditorSegue"){
            let svc = segue.destinationViewController as! AudioEditorViewController;
            svc.fromLibrary = true
            svc.tempFilename1 = tempFilename1
            svc.tempFilename2 = tempFilename2
        
            if currentCategory == 0 {
                if currentCount == 2 {
                    svc.fromLibraryFileName1 = data0[selectedFileIndexRow1]
                    svc.fromLibraryFileName2 = data0[selectedFileIndexRow2]
                }
                else if currentCount == 1 {
                    svc.fromLibraryFileName1 = data0[selectedFileIndexRow1]
                    svc.fromLibraryFileName2 = ""
                }
            }
            else {
                if currentCount == 2 {
                    svc.fromLibraryFileName1 = data1[selectedFileIndexRow1]
                    svc.fromLibraryFileName2 = data1[selectedFileIndexRow2]
                }
                else if currentCount == 1 {
                    svc.fromLibraryFileName1 = data1[selectedFileIndexRow1]
                    svc.fromLibraryFileName2 = ""
                }
            }
        }
    }
    
    
    func valueChanged(segmentedControl: UISegmentedControl) {

        
        if(segmentedControl.selectedSegmentIndex == 0){
            self.data = self.data0
            currentCategory = 0
            player?.stop()
        } else {
            self.data = data1
            currentCategory = 1
            player?.stop()

        }
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    func refresh(sender: AnyObject) {
        
        //clear the data list to repopulate it
        
        data1 = []
        
        //repopulate the new friendlist, there's definitely a more efficient way to do this, but i'm too lazy...
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                for object in objects!{
                    self.data1.append(String(object["audioName"]))
                    let file = object["audioFile"] as! PFFile
                    self.audioFiles1.append(file)
                }
            } else {
                print(error)
            }
            self.tableView.reloadData()
        }
        
        self.refreshControl?.endRefreshing()
    }

    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        player?.stop()
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
