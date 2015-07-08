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
    
    @IBOutlet weak var TableView: UITableView!
    let playlistBuilder = PlaylistBuilder()
    var currentPlaylist : SPTPartialPlaylist?
	var selectedPlaylist : SPTPartialPlaylist?
    var currentSelectedRow:NSIndexPath?
    
    var playlistIDArray = [String]()
    
    @IBOutlet weak var amountSlider: UISlider!

    @IBOutlet weak var extendPlaylistButton: UIButton!

    @IBOutlet weak var extendView: UIView!
    
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
        
        SPTPlaylistList.playlistsForUserWithSession(session) { (error: NSError!, callback: AnyObject!) -> Void in
            if error == nil {
                self.playlistList = callback as! SPTPlaylistList
                self.playlistBuilder.SetPlaylistList(self.playlistList)
                if let playlist = self.playlistList.items[0] as? SPTPartialPlaylist {
                    self.currentPlaylist = playlist
                }
                
                self.TableView.reloadData()
			
            } else {
                println("error caught: " + "\(error.description)")
            }
        }
    }
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if playlistList != nil {
			return playlistList.items.count
		} else {
			return 0
		}
	}
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        
        currentPlaylist = playlistList.items[indexPath.row] as? SPTPartialPlaylist
        performSegueWithIdentifier("ShowDetail", sender: self)
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
        let cellIdentifier = "Playlist Cell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! PlaylistTableViewCell
        
        let playlist = playlistList.items?[indexPath.row] as? SPTPartialPlaylist
        
        if let albumArtwork = playlist?.smallestImage {
            cell.applyImage(albumArtwork.imageURL)
        }
        
        cell.albumName.text = playlistList.items?[indexPath.row].name
        
		if let trackCount = playlistList.items?[indexPath.row].trackCount {
			cell.trackCount.text = "\(trackCount) tracks"
        } else {
            cell.trackCount.text = " "
        }
        
        cell.detailButton.addTarget(self, action: "detailButtonAction:", forControlEvents: UIControlEvents.TouchUpInside)
        cell.detailButton.tag = indexPath.row
        
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
        
        if currentSelectedRow == indexPath {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                extendView.alpha = 0.0
                currentSelectedRow = nil
                return
        }
        
        currentSelectedRow = indexPath
        playlistBuilder.SetPlaylistList(playlistList)
        currentPlaylist = playlistList.items[indexPath.row] as? SPTPartialPlaylist
        extendView.alpha = 1.0
	}
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if currentSelectedRow == indexPath {
            currentSelectedRow = nil
        }
        extendView.alpha = 0.0
    }
    func detailButtonAction (sender: UIButton!) {
        currentPlaylist = playlistList.items[sender.tag] as? SPTPartialPlaylist
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
		
		if self.currentPlaylist != nil {
			var number = Int(self.amountSlider.value)
			
			self.playlistBuilder.buildPlaylist(self.currentPlaylist!, session: self.session, sizeToIncreaseBy: number, name : name, extendOrBuild: false) { result in
				
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
        extendPlaylistButton.setTitle("Extend by \(Int(sender.value)) Tracks", forState: .Normal)
    }
    
    func ShowErrorAlert() {
        let alertView = UIAlertController(title: "429 Error", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
}
