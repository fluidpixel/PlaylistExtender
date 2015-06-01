//
//  PlaylistController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 29/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PlaylistController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var session : SPTSession!
    var playlistList : SPTPlaylistList!
    
    let playlistBuilder = PlaylistBuilder()
    var currentPlaylist : SPTPartialPlaylist?
    

    @IBOutlet weak var Playlist: UIPickerView!
    
    @IBOutlet weak var X: UILabel!
    @IBOutlet weak var SongAddedLabel: UILabel!
    @IBOutlet weak var playlistSlider: UISlider!
    
    @IBOutlet weak var UserButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPlaylists()
        
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func loadPlaylists() {
        
        SPTPlaylistList.playlistsForUserWithSession(session) { (error: NSError!, callback: AnyObject!) -> Void in
            if error == nil {
                self.playlistList = callback as! SPTPlaylistList
            } else {
                println("error caught: " + "\(error.description)")
            }
            
            if self.playlistList.items.count > 1 {
                
                self.Playlist.dataSource = self
                self.Playlist.delegate = self
            }
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int{
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if playlistList != nil {
            if playlistList.items.count > 0{
                return playlistList.items.count
            }
        }
        
        return 0
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        
        if playlistList != nil {
            if playlistList.items.count > row {
                //
                if let item: String? =  playlistList.items?[row].name {
                    return item
                }
                
            }
        }
        return "No Playlists available"
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if playlistList != nil {
            if playlistList.items.count > 0 {
                println(playlistList.items[row])
                currentPlaylist = playlistList.items[row] as? SPTPartialPlaylist
            }
        }
    }
    
    @IBAction func ExtendPlaylistButton(sender: UIButton) {
        
        if currentPlaylist != nil {
            playlistBuilder.buildPlaylist(currentPlaylist!, session: session)
        } else {
            println("Please pick a valid playlist")
        }
    }

    @IBAction func OnSliderDragged(sender: UISlider) {
        X.text = "\(Int(sender.value))"
    }
    
    @IBAction func ReturnToLogin(sender: UIButton) {
        
    }
}
