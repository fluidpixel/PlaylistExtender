//
//  PlaylistController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 29/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PlaylistController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate {
    
    var session : SPTSession!
    var playlistList : SPTPlaylistList!
    var listOfPlaylists = [[String: String]]()
    var numberOfPlaylists = 0
    var numberOfGrabbedPlaylists = 0
    
    @IBOutlet weak var TableView: UITableView!
    let playlistBuilder = PlaylistBuilder()
    var currentPlaylist = [String : String]()
    
	var selectedPlaylist : SPTPartialPlaylist?
    var currentSelectedRow:NSIndexPath?
    
    var playlistIDArray = [String]()
    
    @IBOutlet weak var amountSlider: UISlider!

    @IBOutlet weak var extendPlaylistButton: UIButton!
    @IBOutlet weak var extendPlaylistTitle: UILabel!

    @IBOutlet weak var extendView: UIView!
    @IBOutlet weak var explicitSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let blur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.frame = extendView.bounds
        extendView.insertSubview(effectView, atIndex:0)
        
        TableView.delegate = self
        TableView.dataSource = self
        TableView.backgroundColor = UIColor.darkTextColor()
        
       
        loadPlaylists()
	}
    
    override func viewWillAppear(animated: Bool) {
         navigationItem.title = "Playlist Extender"
    }

    func loadPlaylists() {
        //change this to web api
        playlistBuilder.grabUsersListOfPlaylists(0, thisSession: session) { (result, playlistCount) -> () in
            
            if result.count > 0 {
                self.listOfPlaylists = result
                self.playlistBuilder.SetPlaylistList(result)
                
                self.currentPlaylist = result[0]
                
                self.numberOfPlaylists = playlistCount
                self.numberOfGrabbedPlaylists = self.numberOfGrabbedPlaylists + result.count
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.TableView.reloadData()
                })
                
            }else {
                print("empty/nil playlist")
            }
            
        }
        
    }
	
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == currentSelectedRow {
            return 104
        } else {
            return 84
        }
    }
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if listOfPlaylists.count > 0 {
			return listOfPlaylists.count
		} else {
			return 0
		}
	}
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        currentPlaylist = listOfPlaylists[indexPath.row]
        performSegueWithIdentifier("ShowDetail", sender: self)
        
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
        let cellIdentifier = "Playlist Cell"
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! PlaylistTableViewCell
        cell.backgroundImage.image = UIImage(named: "loginButton")
        let playlist = listOfPlaylists[indexPath.row]
        
        if let albumArtwork = playlist["smallestImage"] {
            cell.applyImage(NSURL(string: albumArtwork)!)
        }
        
        cell.albumName.text = playlist["playlistName"]
        
		if let trackCount = playlist["tracksInPlaylist"] {
			cell.trackCount.text = "\(trackCount) tracks"
        } else {
            cell.trackCount.text = ""
        }
        
        cell.detailButton.addTarget(self, action: "detailButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        cell.detailButton.tag = indexPath.row
        
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        currentPlaylist = listOfPlaylists[indexPath.row]
        
        if currentSelectedRow == indexPath {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            
                UIView.animateWithDuration(0.5, animations: {
                    self.extendView.alpha = 0.0
                })
            
                tableView.beginUpdates()
                currentSelectedRow = nil
                tableView.endUpdates()
            
                return
        }
        
        tableView.beginUpdates()
        currentSelectedRow = indexPath
        tableView.endUpdates()
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell
        playlistBuilder.SetPlaylistList(listOfPlaylists)
        
        amountSlider.maximumValue = max(Float(((Int(currentPlaylist["tracksInPlaylist"]!)))!), 20.0)
        amountSlider.minimumValue = min(Float(((Int(currentPlaylist["tracksInPlaylist"]!)))!), 10.0)
        amountSlider.value = amountSlider.minimumValue
        extendPlaylistButton.setTitle("EXTEND by \(Int(amountSlider.value)) Tracks ✚", forState: .Normal)
        
        extendPlaylistTitle.text =  currentPlaylist["playlistName"]
        
        UIView.animateWithDuration(0.5, animations: {
            self.extendView.alpha = 1.0
        })
	}
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        //load more playlists if more and user scrolls to the bottom of the screen
        if numberOfGrabbedPlaylists == indexPath.row && numberOfGrabbedPlaylists < numberOfPlaylists {
            print("Start loading new playlists")
        }
    }
 
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {

        if let indexPath = currentSelectedRow {
            TableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        UIView.animateWithDuration(0.5, animations: {
            self.extendView.alpha = 0.0
        })
        
        TableView.beginUpdates()
        currentSelectedRow = nil
        TableView.endUpdates()
    }
    
    func detailButtonAction (sender: UIButton!) {
       // currentPlaylist = playlistList
        performSegueWithIdentifier("ShowDetail", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
            if let viewController = segue.destinationViewController as? PlaylistTableViewController {
                navigationItem.title = nil
                viewController.playlist = currentPlaylist
                viewController.Currentsession = session
                viewController.navigationItem.title = currentPlaylist["playlistName"]
            }
        
    }
		
    @IBAction func ExtendPlaylistButton(sender: UIButton) {
        
        let message = "Name Your new playlist"
        
        var txt : UITextField?
        
        let alertView = UIAlertController(title: "Playlist Name", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.textAlignment = NSTextAlignment.Center
            textField.placeholder = self.currentPlaylist["playlistName"]
            txt = textField
        }
        
        alertView.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
		alertView.addAction(UIAlertAction(title: "Copy Existing Tracks", style: UIAlertActionStyle.Default, handler: { UIAlertAction -> Void in
			self.newPlaylist(txt!.text!, extend: true)
		}))

        alertView.addAction(UIAlertAction(title: "Brand New Playlist", style: UIAlertActionStyle.Default, handler: { UIAlertAction -> Void in
		self.newPlaylist(txt!.text!, extend: false)
        }))
	
        self.presentViewController(alertView, animated: true, completion: nil)
    }

	func newPlaylist (name: String, extend:Bool) {
		
		if self.currentPlaylist["playlistName"] != nil {
			let number = Int(self.amountSlider.value)
			
            let defaults = NSUserDefaults.standardUserDefaults()
            let explicitFilter = defaults.boolForKey("explicit_filter_preference")
            
            self.playlistBuilder.buildPlaylist(self.currentPlaylist, session: self.session, sizeToIncreaseBy: number, name : name, extendOrBuild: extend, filter : (explicitFilter)) { result in
				
				if result != nil {
					self.loadPlaylists()
				}
                if result == "429" {
					self.ShowErrorAlert()
				}
			}
			
		} else {
			print("Please pick a valid playlist")
		}
	}
	
    @IBAction func OnSliderDragged(sender: UISlider) {
        extendPlaylistButton.setTitle("EXTEND by \(Int(sender.value)) Tracks ✚", forState: .Normal)
    }
    
    func ShowErrorAlert() {
        let alertView = UIAlertController(title: "429 Error", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
}
