//
//  PlaylistController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 29/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PlaylistController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
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
        
        loadPlaylists()
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
                
                self.TableView.reloadData()
                
            }else {
                println("empty/nil playlist")
            }
            
        }
        
    }
	
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath == currentSelectedRow {
            return 84
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
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! PlaylistTableViewCell
        
        let playlist = listOfPlaylists[indexPath.row]
        
        if let albumArtwork = listOfPlaylists[indexPath.row]["smallestImage"] {
            cell.applyImage(NSURL(string: albumArtwork)!)
        }
        
        cell.albumName.text = listOfPlaylists[indexPath.row]["playlistName"]
        
		if let trackCount = listOfPlaylists[indexPath.row]["tracksInPlaylist"] {
			cell.trackCount.text = "\(trackCount) tracks"
        } else {
            cell.trackCount.text = ""
        }
        
        cell.detailButton.addTarget(self, action: "detailButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        cell.detailButton.tag = indexPath.row
        
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
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
        currentPlaylist = listOfPlaylists[indexPath.row]
        playlistBuilder.SetPlaylistList(listOfPlaylists)
        
        UIView.animateWithDuration(0.5, animations: {
            self.extendView.alpha = 1.0
        })
	}
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        //load more playlists if more and user scrolls to the bottom of the screen
        if numberOfGrabbedPlaylists == indexPath.row && numberOfGrabbedPlaylists < numberOfPlaylists {
            println("Start loading new playlists")
        }
    }
 
    func detailButtonAction (sender: UIButton!) {
       // currentPlaylist = playlistList
        performSegueWithIdentifier("ShowDetail", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
            if var viewController = segue.destinationViewController as? PlaylistTableViewController {
            
                viewController.playlist = currentPlaylist
                viewController.Currentsession = session
            }
        
    }
		
    @IBAction func ExtendPlaylistButton(sender: UIButton) {
        
        let message = "Name Your new playlist"
        
        var txt : UITextField?
        
        let alertView = UIAlertController(title: "Playlist Name", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            textField.textAlignment = NSTextAlignment.Center
            txt = textField
        }
        
        alertView.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
		alertView.addAction(UIAlertAction(title: "Copy Existing Tracks", style: UIAlertActionStyle.Default, handler: { UIAlertAction -> Void in
			self.newPlaylist(txt!.text, extend: true)
		}))

        alertView.addAction(UIAlertAction(title: "Brand New Playlist", style: UIAlertActionStyle.Default, handler: { UIAlertAction -> Void in
		self.newPlaylist(txt!.text, extend: false)
        }))
	
        self.presentViewController(alertView, animated: true, completion: nil)
    }

	func newPlaylist (name: String, extend:Bool) {
		
		if self.currentPlaylist["playlistName"] != nil {
			var number = Int(self.amountSlider.value)
			
            self.playlistBuilder.buildPlaylist(self.currentPlaylist, session: self.session, sizeToIncreaseBy: number, name : name, extendOrBuild: extend, filter : (explicitSwitch.on)) { result in
				
				if result != nil {
					
					self.loadPlaylists()
					
				}
                if result == "429" {
					self.ShowErrorAlert()
				}
			}
			
		} else {
			println("Please pick a valid playlist")
		}
	}
	
    @IBAction func OnSliderDragged(sender: UISlider) {
        extendPlaylistButton.setTitle("EXTEND by \(Int(sender.value)) Tracks", forState: .Normal)
    }
    
    func ShowErrorAlert() {
        let alertView = UIAlertController(title: "429 Error", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
}
