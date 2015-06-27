//
//  PlaylistController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 29/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PlaylistController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var session : SPTSession!
    var playlistList : SPTPlaylistList!
    
    let playlistBuilder = PlaylistBuilder()
    var currentPlaylist : SPTPartialPlaylist?
	
    var playlistIDArray = [String]()
    
	@IBOutlet weak var amountSlider: UISlider!
//    @IBOutlet weak var CopyOrCreateSwitch: UISwitch!

//    @IBOutlet weak var Playlist: UIPickerView!
	
//    @IBOutlet weak var X: UILabel!
//    @IBOutlet weak var SongAddedLabel: UILabel!
//    @IBOutlet weak var playlistSlider: UISlider!
	
    @IBOutlet weak var extendPlaylistButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                
                self.tableView.reloadData()
			
            } else {
                println("error caught: " + "\(error.description)")
            }
            
//            self.Playlist.reloadAllComponents()
            if self.playlistList.items.count > 1 {
                
//                self.Playlist.dataSource = self
//                self.Playlist.delegate = self
//                self.Playlist.selectRow(0, inComponent: 0, animated: false)
            }
        }
    }
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if playlistList != nil {
			return playlistList.items.count
		} else {
			return 0
		}
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = self.tableView.dequeueReusableCellWithIdentifier("playlist cell") as! UITableViewCell
		cell.textLabel?.text = playlistList.items?[indexPath.row].name
		if let trackCount = playlistList.items?[indexPath.row].trackCount {
			cell.detailTextLabel?.text = "\(trackCount)"
		}
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		playlistBuilder.SetPlaylistList(playlistList)
		currentPlaylist = playlistList.items[indexPath.row] as? SPTPartialPlaylist
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
					
				}else if result == "429" {
					self.ShowErrorAlert()
				}
			}
			
		} else {
			println("Please pick a valid playlist")
		}
	}
	
    @IBAction func OnSliderDragged(sender: UISlider) {
		extendPlaylistButton.setTitle("Extend by \(Int(sender.value)) Playlists", forState: .Normal)
    }
	
    @IBAction func ReturnToLogin(sender: UIButton) {
	
    }
    
    func ShowErrorAlert() {
        let alertView = UIAlertController(title: "429 Error", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertView.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alertView, animated: true, completion: nil)
    }
}
