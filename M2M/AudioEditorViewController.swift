//
//  AudioEditorViewController.swift
//  M2M
//
//  Created by Mark Chae on 11/11/15.
//  Copyright (c) 2015 Lin. All rights reserved.
//

import AudioToolbox
import AVFoundation
import UIKit
import Parse

class AudioEditorViewController: UIViewController, AVAudioPlayerDelegate {
    
    var player : AVAudioPlayer!

    var firstAudioFileData: NSData!
    var secondAudioFileData: NSData!
    var editProductFileData: NSData!

    var activitiyIndicator: UIActivityIndicatorView = UIActivityIndicatorView()

    var firstAudioFile: PFFile!
    var secondAudioFile : PFFile!
    var editProductFile: PFFile!
    
    var fromLibrary = false
    var fromRecorder = false
    var fromLibraryFileName1 = ""
    var fromLibraryFileName2 = ""
    var fromRecorderFileName = ""
    var editProductFileName = ""
    var audioFileToSendName : String!
    
    var tempFilename1 = ""
    var tempFilename2 = ""
    
    var soundFileURL: NSURL!
    
    @IBOutlet var Play: UIButton!
    
    @IBOutlet var Play2: UIButton!
    
    @IBOutlet var Play3: UIButton!
    
    @IBOutlet var Id: UILabel!
    
    @IBOutlet var Id2: UILabel!
    
    @IBOutlet var Id3: UILabel!

    @IBOutlet var Edit: UIButton!
    
    @IBOutlet var Discard: UIButton!
    
    @IBOutlet var Discard2: UIButton!

    @IBOutlet var Discard3: UIButton!
   
    @IBOutlet var LibraryBtn: UIButton!
    
    @IBOutlet var fieldbar3: UIImageView!
    
    
    
    //Let the user to edit the music and allow a pop-up window to choose between overlaying and appending
    @IBAction func Edit(sender: UIButton) {
        let alert = UIAlertController(title: "Edit", message: nil,
            preferredStyle: .ActionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) {(action) in}
        alert.addAction(cancel)
        let append = UIAlertAction(title: "Append", style: .Default) {(action) in
            self.append(self.firstAudioFileData, audio2: self.secondAudioFileData)
            print("Appended ",self.Id.text, " to ",self.Id2.text)
        }
        alert.addAction(append)
        let overlay = UIAlertAction(title: "Overlay", style: .Default) {(action) in
            self.overlay(self.firstAudioFileData, audio2: self.secondAudioFileData)
             print("Overlaid ",self.Id.text, " over ",self.Id2.text)
        }
        alert.addAction(overlay)
        if firstAudioFileData == nil || secondAudioFileData == nil {
            let errorMsg = UIAlertController(title: "Error", message: "You need to choose two files before editing", preferredStyle: .Alert)
            let ok = UIAlertAction(title: "OK", style: .Cancel) {(action) in}
            errorMsg.addAction(ok)
            self.presentViewController(errorMsg, animated: true, completion: nil)
        }
        else {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //need error checking for nil
    @IBAction func Play(sender: UIButton) {
        if player != nil && player.playing {
            player.stop()
        }
        else if firstAudioFileData != nil {
          self.playAudio(firstAudioFileData)
        }
        else {
        }
    }
    
    @IBAction func Play2(sender: UIButton) {
        if player != nil && player.playing {
            player.stop()
        }
        else if secondAudioFileData != nil {
            self.playAudio(secondAudioFileData!)
        }
        else {
        }
    }
    
    @IBAction func Play3(sender: UIButton) {
        if player != nil && player.playing {
            player.stop()
        }
        else if editProductFileData != nil {
            self.playAudio(editProductFileData!)
        }
        else {
        }
    }
    
    func playAudio(data: NSData) {
        do {
            self.player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.prepareToPlay()
            player.volume = 1.0
            player.play()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        }
    }
    
    //Allow the user to discard the current file and pick another one from the library
    @IBAction func Discard(sender: UIButton) {
        firstAudioFileData = nil
        firstAudioFile = nil
        fromLibrary = false
        fromRecorder = false
        Id.text = "No File"
    }
    @IBAction func Discard2(sender: UIButton) {
        secondAudioFileData = nil
        secondAudioFile = nil
        fromLibrary = false
        fromRecorder = false
        Id2.text = "No File"
    }
    
    @IBAction func Discard3(sender: UIButton) {
        editProductFileData = nil
        editProductFile = nil
        fromLibrary = false
        fromRecorder = false
        Id3.text = "No File"
        Id3.hidden = true
        Play3.hidden = true
        Play3.enabled = false
        Discard3.hidden = true
        Discard3.enabled = false
        Edit.hidden = false
        Edit.enabled = true
        fieldbar3.hidden = true
    }
    
    
    func loadFirstAudioFile(fileName: String) {
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.whereKey("audioName", equalTo: fileName)
                do {
                    let object = try query.getFirstObject()
                    self.firstAudioFile = object["audioFile"] as? PFFile
                    self.firstAudioFileData = try self.firstAudioFile.getData()
                    self.Id.text = fileName
                    print("Loaded ",fileName)
                }
                catch {
                    print(error)
                }
    }
    
    func loadSecondAudioFile(fileName: String) {
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.whereKey("audioName", equalTo: fileName)
                do {
                    let object = try query.getFirstObject()
                    self.secondAudioFile = object["audioFile"] as? PFFile
                    self.secondAudioFileData = try self.secondAudioFile.getData()
                    self.Id2.text = fileName
                    print("Loaded ",fileName)
                }
                catch {
                    print(error)
                }
    }
    
  
    override func viewWillAppear(animated: Bool) {
        if !(self.tempFilename1 ?? "").isEmpty {
            loadFirstAudioFile(tempFilename1)
        }
        if !(self.tempFilename2 ?? "").isEmpty {
            loadSecondAudioFile(tempFilename2)
        }
        
        if fromLibrary {
            print("Received from Library: ",fromLibraryFileName1)
            print("Received from Library: ",fromLibraryFileName2)
            if !(fromLibraryFileName2 ?? "").isEmpty {
                if self.firstAudioFileData == nil && self.secondAudioFileData == nil {
                    loadFirstAudioFile(fromLibraryFileName1)
                    loadSecondAudioFile(fromLibraryFileName2)
                }
                else if self.firstAudioFile != nil && self.secondAudioFileData == nil  {
                    let alert = UIAlertController(title: "Editor Full", message: "You already have a file in the editor. Would you like to replace it?", preferredStyle: .Alert)
                    let no = UIAlertAction(title: "No", style: .Cancel) {(action) in}
                    alert.addAction(no)
                    let yes = UIAlertAction(title: "Yes", style: .Default) {(action) in
                        self.loadFirstAudioFile(self.fromLibraryFileName1)
                        self.loadSecondAudioFile(self.fromLibraryFileName2)
                    }
                    alert.addAction(yes)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else if self.firstAudioFile == nil && self.secondAudioFileData != nil  {
                    let alert = UIAlertController(title: "Editor Full", message: "You already have a file in the editor. Would you like to replace it?", preferredStyle: .Alert)
                    let no = UIAlertAction(title: "No", style: .Cancel) {(action) in}
                    alert.addAction(no)
                    let yes = UIAlertAction(title: "Yes", style: .Default) {(action) in
                        self.loadFirstAudioFile(self.fromLibraryFileName1)
                        self.loadSecondAudioFile(self.fromLibraryFileName2)
                    }
                    alert.addAction(yes)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Editor Full", message: "You already have two files in the editor. Would you like to replace them?", preferredStyle: .Alert)
                    let no = UIAlertAction(title: "No", style: .Cancel) {(action) in}
                    alert.addAction(no)
                    let yes = UIAlertAction(title: "Yes", style: .Default) {(action) in
                        self.loadFirstAudioFile(self.fromLibraryFileName1)
                        self.loadSecondAudioFile(self.fromLibraryFileName2)
                    }
                    alert.addAction(yes)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            else {
                if self.firstAudioFileData==nil {
                    loadFirstAudioFile(fromLibraryFileName1)
                }
                else if self.secondAudioFileData==nil {
                    loadSecondAudioFile(fromLibraryFileName1)
                }
                else {
                    let alert = UIAlertController(title: "Editor Full", message: "You already have two files in the editor. Would you like to replace one?", preferredStyle: .Alert)
                    let no = UIAlertAction(title: "No", style: .Cancel) {(action) in}
                    alert.addAction(no)
                    let yes = UIAlertAction(title: "Yes", style: .Default) {(action) in
                        self.loadSecondAudioFile(self.fromLibraryFileName1)
                    }
                    alert.addAction(yes)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
        else if fromRecorder {
            print("Received from Recorder: ",fromRecorderFileName)
            if self.firstAudioFileData==nil {
                loadFirstAudioFile(fromRecorderFileName)
            }
            else if self.secondAudioFileData==nil {
                loadSecondAudioFile(fromRecorderFileName)
            }
            else {
                let alert = UIAlertController(title: "Editor Full", message: "You already have two files in the editor. Would you like to replace one?", preferredStyle: .Alert)
                let no = UIAlertAction(title: "No", style: .Cancel) {(action) in}
                alert.addAction(no)
                let yes = UIAlertAction(title: "Yes", style: .Default) {(action) in
                    self.loadSecondAudioFile(self.fromRecorderFileName)
                }
                alert.addAction(yes)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        self.fromLibrary = false
        self.fromRecorder = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func append(audio1: NSData, audio2: NSData) {
        /*let file1 = audio1
        let string1 = file1.url
        let file2 = audio2
        let string2 = file2.url
        
        let composition = AVMutableComposition()
        let track1:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        let track2:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        let documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent(" ")
        print(fileDestinationUrl)
        
        
        let url1 = NSURL(fileURLWithPath: string1!)
        let url2 = NSURL(fileURLWithPath: string2!)
        
        let avAsset1 = AVURLAsset(URL: url1, options: nil)
        let avAsset2 = AVURLAsset(URL: url2, options: nil)
        
        let tracks1 =  avAsset1.tracksWithMediaType(AVMediaTypeAudio)
        let tracks2 =  avAsset2.tracksWithMediaType(AVMediaTypeAudio)
        
        //error here calling element 0 in empty array
        let assetTrack1:AVAssetTrack = tracks1[0]
        let assetTrack2:AVAssetTrack = tracks2[0]
        
        let duration1: CMTime = assetTrack1.timeRange.duration
        let duration2: CMTime = assetTrack2.timeRange.duration
        
        let timeRange1 = CMTimeRangeMake(kCMTimeZero, duration1)
        let timeRange2 = CMTimeRangeMake(duration1, duration2)
        
        do {
                try track1.insertTimeRange(timeRange1, ofTrack: assetTrack1, atTime: kCMTimeZero)
                try track2.insertTimeRange(timeRange2, ofTrack: assetTrack2, atTime: duration1)
            }
        catch {
            print(error)
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport!.outputFileType = AVFileTypeAppleM4A
        assetExport!.outputURL = fileDestinationUrl
        assetExport!.exportAsynchronouslyWithCompletionHandler({
            switch assetExport!.status{
            case  AVAssetExportSessionStatus.Failed:
                print("Failed \(assetExport!.error)")
            case AVAssetExportSessionStatus.Cancelled:
                print("Cancelled \(assetExport!.error)")
            default:
                print("Success")
            }
            let format = NSDateFormatter()
            format.dateFormat="yyyy-MM-dd-HH-mm-ss"
            self.Id3.text = "Append-\(format.stringFromDate(NSDate())).m4a"
            self.editProductFileData = fileDestinationUrl.dataRepresentation
            self.Id3.hidden = false
            self.Play3.hidden = false
            self.Play3.enabled = true
            self.Discard3.hidden = false
            self.Discard3.enabled = true
            self.Edit.hidden = true
            self.Edit.enabled = false
            self.fieldbar3.hidden = false
        })*/
        
        let final = NSMutableData.init(data: audio1)
        let final2 = NSMutableData.init(data: audio2)
        final.appendData(final2)
        let final3 = NSData(data: final)
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let audioName = "Append-\(format.stringFromDate(NSDate())).m4a"
        Id3.text = audioName
        audioFileToSendName = audioName
        editProductFileData = final3
        Id3.hidden = false
        Play3.hidden = false
        Play3.enabled = true
        Discard3.hidden = false
        Discard3.enabled = true
        Edit.hidden = true
        Edit.enabled = false
        fieldbar3.hidden = false
        
        displayPopup(self.Id3.text!, recoringData: final3)
    }
    
    func overlay(audio1: NSData, audio2:  NSData) {
        /*let composition = AVMutableComposition()
        var track1:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio,
            preferredTrackID: CMPersistentTrackID())
        var track2:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        var fileDestinationUrl = documentDirectoryURL.URLByAppendingPathComponent(" ")
        print(fileDestinationUrl)
        
        
        var url1 = audio1
        var url2 = audio2
        
        
        //var avAsset1 = AVURLAsset(URL: url1, options: nil)
        //var avAsset2 = AVURLAsset(URL: url2, options: nil)
        
        var tracks1 =  avAsset1.tracksWithMediaType(AVMediaTypeAudio)
        var tracks2 =  avAsset2.tracksWithMediaType(AVMediaTypeAudio)
        
        var assetTrack1:AVAssetTrack = tracks1[0]
        var assetTrack2:AVAssetTrack = tracks2[0]
        
        
        var duration1: CMTime = assetTrack1.timeRange.duration
        var duration2: CMTime = assetTrack2.timeRange.duration
        
        var timeRange1 = CMTimeRangeMake(kCMTimeZero, duration1)
        var timeRange2 = CMTimeRangeMake(duration1, duration2)
        
        do {
            try track1.insertTimeRange(timeRange1, ofTrack: assetTrack1, atTime: kCMTimeZero)
            try track2.insertTimeRange(timeRange2, ofTrack: assetTrack2, atTime: duration1)
        }
        catch _ {
        }
        
        var assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        assetExport!.outputFileType = AVFileTypeAppleM4A
        assetExport!.outputURL = fileDestinationUrl
        assetExport!.exportAsynchronouslyWithCompletionHandler({
            switch assetExport!.status{
            case  AVAssetExportSessionStatus.Failed:
                print("Failed \(assetExport!.error)")
            case AVAssetExportSessionStatus.Cancelled:
                print("Cancelled \(assetExport!.error)")
            default:
                print("Success")
                //Add new file to library, unfinished
            }
            
        })*/
        let final = NSMutableData()
        final.appendData(audio1)
        final.appendData(audio2)
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let audioName = "Overlay-\(format.stringFromDate(NSDate())).m4a"
        Id3.text = audioName
        audioFileToSendName = audioName
        editProductFileData = final
        Id3.hidden = false
        Play3.hidden = false
        Play3.enabled = true
        Discard3.hidden = false
        Discard3.enabled = true
        Edit.hidden = true
        Edit.enabled = false
        fieldbar3.hidden = false
        displayPopup(audioName, recoringData: final)
        
    }
    
    func displayPopup(var recordingName: String, recoringData: NSData) {
        //************** alert to name the recording *******************
        let alert = UIAlertController(title: "Rename",
            message: "Name Recording",
            preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Save to your library", style: .Default, handler: {[unowned alert] action in
            //print("yes was tapped")
            if let textFields = alert.textFields{
                let tfa = textFields as [UITextField]
                let text = tfa[0].text
                recordingName = text!
                self.audioFileToSendName = text!
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
            self.saveToParse(recordingName, recordingData: recoringData)
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

    func saveToParse(recordingName: String, recordingData: NSData) {
        
        let soundFile = PFFile(name: recordingName, data: recordingData)
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
                //self.latestRecordingName = recordingName
                //ends activity indicator
                self.activitiyIndicator.stopAnimating()
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }
        })
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backButton(sender: AnyObject) {
        if fromLibrary {
            performSegueWithIdentifier("editorToLibrarySegue", sender: self)
        } else {
            performSegueWithIdentifier("editorToRecorderSegue", sender: self)
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "editorToLibrarySegue") {
            let svc = segue.destinationViewController as! MusicLibraryViewController;
            svc.fromEditor = true
            if Id.text != "No File" {
                self.tempFilename1 = Id.text!
                print("Global ",tempFilename1)
            }
            else {
                tempFilename1 = ""
            }
            if Id2.text != "No File" {
                self.tempFilename2 = Id2.text!
                print("Global ",tempFilename2)
            }
            else {
                tempFilename2 = ""
            }
            svc.tempFilename1 = tempFilename1
            svc.tempFilename2 = tempFilename2
        }
        if (segue.identifier == "editorToRecorderSegue") {
            let svc = segue.destinationViewController as! AudioRecorderViewController;
            if Id.text != "No File" {
                self.tempFilename1 = Id.text!
                print("Global ",tempFilename1)
            }
            else {
                tempFilename1 = ""
            }
            if Id2.text != "No File" {
                self.tempFilename2 = Id2.text!
                print("Global ",tempFilename2)
            }
            else {
                tempFilename2 = ""
            }
            svc.tempFilename1 = tempFilename1
            svc.tempFilename2 = tempFilename2
        }
        if (segue.identifier == "editorToSenderSegue"){
            let svc = segue.destinationViewController as! sendToFriendsViewController;
            if let audioName = audioFileToSendName {
                svc.recordingName = audioName
            }
        }

    }
    

}
