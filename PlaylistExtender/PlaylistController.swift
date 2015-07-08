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
	
    var playlistIDArray = [String]()
    
    @IBOutlet weak var amountSlider: UISlider!

    @IBOutlet weak var extendPlaylistButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.TableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "playlist cell")
        
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
		
        let cellIdentifier = "Playlist cell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier)
            cell?.textLabel!.adjustsFontSizeToFitWidth = true
            cell?.textLabel!.minimumScaleFactor = 0.5
            cell?.accessoryType = UITableViewCellAccessoryType.DetailDisclosureButton
        }
		cell!.textLabel?.text = playlistList.items?[indexPath.row].name
		if let trackCount = playlistList.items?[indexPath.row].trackCount {
        
			cell!.detailTextLabel?.text = "\(trackCount) tracks"
		}
		return cell!
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		playlistBuilder.SetPlaylistList(playlistList)
		currentPlaylist = playlistList.items[indexPath.row] as? SPTPartialPlaylist
        
        
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
