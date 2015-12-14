//
//  AudioRecorderViewController.swift
//  M2M
//
//  Created by Sheng-Hua.Lin on 11/11/15.
//  Copyright © 2015 Lin. All rights reserved.
//

import UIKit
import AVFoundation
import Parse
import ParseUI

//var soundFileURL:NSURL!

class AudioRecorderViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var recorder: AVAudioRecorder!
    
    var player:AVAudioPlayer!
    
    var meterTimer:NSTimer!
    
    var soundFileURL:NSURL!
    
    var recordingExists = false
    
    var activitiyIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    
    //Reference to pass to the Editor
    var latestRecordingName = ""
    
    var tempFilename1 = ""
    var tempFilename2 = ""
    
    @IBOutlet var Record: UIButton!
    
    @IBOutlet var Play: UIButton!
    
    @IBOutlet var Stop: UIButton!
    
    @IBOutlet var Status: UILabel!
    
    
    override func viewDidLoad() {
                
        super.viewDidLoad()
        
        var newCount = 0
        
        let query = PFQuery(className: "sentAudioFiles")
        query.whereKey("receiverUsername", equalTo: (PFUser.currentUser()?.username)!)
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                newCount = (objects?.count)!
                if newCount != 0 {
                    let tabArray = self.tabBarController?.tabBar.items as NSArray!
                    let tabItem = tabArray.objectAtIndex(1) as! UITabBarItem
                    tabItem.badgeValue = String(newCount)
                }
            } else {
                print(error)
            }
        }
        
        Stop.enabled = false
        Play.enabled = false
        
        if soundFileURL != nil {
            Record.enabled = false
        }
        
        //setSessionPlayback()
        //askForNotifications()
        //checkHeadphones()
        
    }
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let min = Int(recorder.currentTime / 60)
            let sec = Int(recorder.currentTime % 60)
            let s = String(format: "%02d:%02d", min, sec)
            Status.text = s
            recorder.updateMeters()
            
            //this part is for the progress bar
            //let averageAudio = recorder.averagePowerForChannel(0) * -1
            
        } else if !recorder.recording {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        recorder = nil
        player = nil
    }
    
    
    @IBAction func record(sender: UIButton) {
        
        if player != nil && player.playing {
            player.stop()
        }
        
        if recorder == nil {
            print("recording. recorder nil")
            //Record.setTitle("Pause", forState: .Normal)
            Play.enabled = false
            Stop.enabled = true
            recordWithPermission(true)
            return
        }
        
        if recorder != nil && recorder.recording {
            print("pausing")
            recorder.pause()
            //Record.setTitle("Continue", forState: .Normal)
        } else {
            print("recording")
            //Record.setTitle("Pause", forState: .Normal)
            Play.enabled = false
            Stop.enabled = true
            recordWithPermission(false)
        }
        
    }
    
    @IBAction func play(sender: UIButton) {
        play()
        
    }
    
    @IBAction func stop(sender: UIButton) {
        print("stop")
        
        recorder?.stop()
        player?.stop()
        
        meterTimer.invalidate()
        
        //************* saving the recording *******************
        
        if !Play.enabled {
            
            let format = NSDateFormatter()
            format.dateFormat="yyyy-MM-dd-HH-mm-ss"
            var recordingName = "recording-\(format.stringFromDate(NSDate())).m4a"
            
            recordingExists = true
            
            //************** alert to name the recording *******************
            let alert = UIAlertController(title: "Rename",
                message: "Name Recording",
                preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "Save to your recordings", style: .Default, handler: {[unowned alert] action in
                //print("yes was tapped")
                if let textFields = alert.textFields{
                    let tfa = textFields as [UITextField]
                    let text = tfa[0].text
                    recordingName = text!
                }
                
                //start activity indicator
                self.activitiyIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
                self.activitiyIndicator.center = self.view.center
                self.activitiyIndicator.hidesWhenStopped = true
                self.activitiyIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
                self.view.addSubview(self.activitiyIndicator)
                self.activitiyIndicator.startAnimating()
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                
                // attempt to save to Parse
                self.saveToParse(recordingName)
            }))
            
            alert.addAction(UIAlertAction(title: "Don't save", style: .Default, handler: {action in
                print("no was tapped")
                
                if let textFields = alert.textFields{
                    let tfa = textFields as [UITextField]
                    let text = tfa[0].text
                    recordingName = text!
                }
            }))
            
            alert.addTextFieldWithConfigurationHandler({textfield in
                textfield.placeholder = "Enter a filename"
                textfield.text = recordingName
            })
            
            self.presentViewController(alert, animated:true, completion:nil)
            //******************************************************
            
        }
        
        if soundFileURL != nil {
            Record.enabled = false
        }
        
        //******************************************************
        
        Record.setTitle("Record", forState: .Normal)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
            Play.enabled = true
            Stop.enabled = false
            //Record.enabled = true
        } catch let error as NSError {
            print("could not be active")
            print(error.localizedDescription)
        }
    }
    
    func saveToParse(recordingName: String) {
        let soundFile = PFFile(name: recordingName, data: NSData(contentsOfURL: soundFileURL!)!)
        let testClass = PFObject(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        testClass["audioName"] = recordingName
        testClass["audioFile"] = soundFile
        testClass["author"] = (PFUser.currentUser()?.username)!
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
                self.latestRecordingName = recordingName
                //ends activity indicator
                self.activitiyIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        })
    }
    
    func play() {
        var url:NSURL?
        if self.recorder != nil {
            url = self.recorder.url
        } else {
            url = soundFileURL!
        }
        print("playing \(url)")
        
        do {
            self.player = try AVAudioPlayer(contentsOfURL: url!)
            Stop.enabled = true
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        }
    }
    
    
    @IBAction func discardAudio(sender: AnyObject) {
        
        let alert = UIAlertController(title: "Discard Recording",
            message: "Are You Sure?",
            preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {action in
            print("yes was tapped")
            self.Record.enabled = true
            self.Play.enabled = false
            self.Stop.enabled = false
            self.Status.text = "00:00"
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .Default, handler: {action in
            print("no was tapped")
        }))
        
        self.presentViewController(alert, animated:true, completion:nil)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "recorderToEditorSegue"){
            let svc = segue.destinationViewController as! AudioEditorViewController
            
            if soundFileURL != nil {
                //svc.url = soundFileURL   //clearly audioEditorViewController does have url, but it says it doesnt...
                svc.fromRecorder = true
                svc.fromRecorderFileName = self.latestRecordingName
                svc.tempFilename1 = tempFilename1
                svc.tempFilename2 = tempFilename2
                if !(self.tempFilename1 ?? "").isEmpty {
                    svc.loadFirstAudioFile(tempFilename1)
                }
                if !(self.tempFilename2 ?? "").isEmpty {
                    svc.loadFirstAudioFile(tempFilename2)
                }
            }
        }
    }
    
    
    func setupRecorder() {
        let format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        let currentFileName = "recording-\(format.stringFromDate(NSDate())).m4a"

        print(currentFileName)
        
        let documentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        soundFileURL = documentsDirectory.URLByAppendingPathComponent(currentFileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(soundFileURL.absoluteString) {
            print("soundfile \(soundFileURL.absoluteString) exists")
        }
        
        let recordSettings:[String : AnyObject] = [
            AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        do {
            recorder = try AVAudioRecorder(URL: soundFileURL, settings: recordSettings)
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch let error as NSError {
            recorder = nil
            print(error.localizedDescription)
        }
        
    }
    
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    print("Permission to record granted")
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                        target:self,
                        selector:"updateAudioMeter:",
                        userInfo:nil,
                        repeats:true)
                } else {
                    print("Permission to record not granted")
                }
            })
        } else {
            print("requestRecordPermission unrecognized")
        }
    }
    
    func setSessionPlayAndRecord() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            print("could not set session category")
            print(error.localizedDescription)
        }
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
    
    func askForNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"background:",
            name:UIApplicationWillResignActiveNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"foreground:",
            name:UIApplicationWillEnterForegroundNotification,
            object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector:"routeChange:",
            name:AVAudioSessionRouteChangeNotification,
            object:nil)
    }
    
    func bar() {
        
    }
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    /*
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder,
        successfully flag: Bool) {
            print("finished recording \(flag)")
            Stop.enabled = false
            Play.enabled = true
            Record.setTitle("Record", forState:.Normal)
            
            // iOS8 and later
            let alert = UIAlertController(title: "Recorder",
                message: "Finished Recording",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: {action in
                print("keep was tapped")
            }))
            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {action in
                print("delete was tapped")
                self.recorder.deleteRecording()
            }))
            //self.presentViewController(alert, animated:true, completion:nil)
    }
    */
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder,
        error: NSError?) {
            
            if let e = error {
                print("\(e.localizedDescription)")
            }
    }
    
    @IBOutlet var averageImageView: UIImageView!
    func averageRadial (average: Int) {
        switch average {
        case average: averageImageView.image = UIImage(named: "average\(String(average))radial")
        default: averageImageView.image = UIImage(named: "average0radial.png")
        }
    }
    
//    func crossfadeTransition() {
//        let transition = CATransaction()
//        transition. = kCATransitionFade
//        transition. = 0.2
//    }

}
