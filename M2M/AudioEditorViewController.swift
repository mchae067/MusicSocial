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

    var firstAudioFile: PFFile!
    var secondAudioFile : PFFile!
    var editProductFile: PFFile!
    
    var fromLibrary = false
    var fromRecorder = false
    var fromLibraryFileName1 = ""
    var fromLibraryFileName2 = ""
    var fromRecorderFileName = ""
    var editProductFileName = ""
    
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
        self.presentViewController(alert, animated: true, completion: nil)
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
    }
    
    
    func loadFirstAudioFile(fileName: String) {
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.whereKey("audioName", equalTo: fileName)
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                self.firstAudioFile = object!["audioFile"] as? PFFile
                self.firstAudioFile.getDataInBackgroundWithBlock({ (data, error) -> Void in
                    if error == nil {
                        self.firstAudioFileData = data
                        self.Id.text = fileName
                        print("Loaded ",fileName)
                        self.fromLibrary = false
                        self.fromRecorder = false
                    }
                    else {
                        print(error)
                    }
                })
            }
            else {
                print(error)
            }
        }
    }
    
    func loadSecondAudioFile(fileName: String) {
        let query = PFQuery(className: "\((PFUser.currentUser()?.username)!)_audioFiles")
        query.whereKey("audioName", equalTo: fileName)
        query.getFirstObjectInBackgroundWithBlock { (object, error) -> Void in
            if error == nil {
                self.secondAudioFile = object!["audioFile"] as? PFFile
                self.secondAudioFile.getDataInBackgroundWithBlock({ (data, error) -> Void in
                    if error == nil {
                        self.secondAudioFileData = data
                        self.Id2.text = fileName
                        print("Loaded ",fileName)
                        self.fromLibrary = false
                        self.fromRecorder = false
                    }
                    else {
                        print(error)
                    }
                })
            }
            else {
                print(error)
            }
        }
    }
    
  
    override func viewWillAppear(animated: Bool) {
        /*if !(self.tempFilename1 ?? "").isEmpty {
            loadFirstAudioFile(tempFilename1)
        }
        if !(self.tempFilename2 ?? "").isEmpty {
            loadSecondAudioFile(tempFilename2)
        }*/
        
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
        catch _ {
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
        })*/
        let final = NSMutableData()
        final.appendData(audio1)
        final.appendData(audio2)
        let format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        Id3.text = "Append-\(format.stringFromDate(NSDate())).m4a"
        editProductFileData = final
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
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        Id3.text = "Overlay-\(format.stringFromDate(NSDate())).m4a"
        editProductFileData = final


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
            
        }

    }
    

}
