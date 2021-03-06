//
//  PlaylistTableViewController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 02/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import Foundation

struct storeData {
  
    //dictionary to store playlists that have already been fetched
    private static var storedPlaylists = [String : [[String]]]()

}

class PlaylistTableViewController: UITableViewController {

    var builder = PlaylistBuilder()
    
    var playlist = [String: String]()
    var Currentsession : SPTSession?
    var list = [[String]]()
    
    override func viewDidLoad() {
        
//        dispatch_async(dispatch_get_main_queue(),{
//            self.title = self.playlist["playlistName"]
//        })
//        
        tableView.backgroundColor = UIColor.darkTextColor()
        
        builder.SetupSession(Currentsession!)
        if storeData.storedPlaylists[self.playlist["playlistID"]!] == nil {
            builder.GrabTracksFromPlaylist(0, tracksInPlaylist: Int(playlist["tracksInPlaylist"]!), playlist: playlist) { (result) -> () in
                if result != nil && result!.count != 0 {
                    self.list = result!
                    storeData.storedPlaylists[self.playlist["playlistID"]!] = result!
                    dispatch_async(dispatch_get_main_queue(),{
                        self.tableView.reloadData()
                    })
                }
            }
        } else {
            self.list = storeData.storedPlaylists[self.playlist["playlistID"]!]!
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return list.count
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // delete entry 
            
            let trackURI = list[indexPath.row][3]
            
            list[indexPath.row].removeAll(keepCapacity: false)
            list.removeAtIndex(indexPath.row)
            self.tableView.reloadData()
            
            //call spotify 
            builder.deleteTrackFromPlaylist(playlist["playlistID"]!, trackURI: trackURI, pos : indexPath.row, completionHandler: { result in
                
            })
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell") as! CustomTableViewCell
        
        //todo - add image
        
        var artistText = ""
        if list.count > 0  {
            cell.applyImage("\(list[indexPath.row][1])")
            cell.Title.text = "\(list[indexPath.row][0])"
            
            for var i = 4; i < list[indexPath.row].count; i++ {
                if i != 4 {
                    artistText = artistText + ", "
                }
                artistText = artistText + " \(list[indexPath.row][i])"
            }
            
            cell.DetailLabel.text = " \(artistText) - \(list[indexPath.row][2])"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        
//        if let viewController = segue.destinationViewController as? PlaylistController {
//            viewController.navigationItem.title = "Playlist Extender"
//        }
//        
//    }
}
