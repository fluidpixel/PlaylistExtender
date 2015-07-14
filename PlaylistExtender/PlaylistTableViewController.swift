//
//  PlaylistTableViewController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 02/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import Foundation

class PlaylistTableViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {

    var builder = PlaylistBuilder()
    var playlist = [String: String]()
    var Currentsession : SPTSession?
    var list = [[String]]()
    
    override func viewDidLoad() {
        
        dispatch_async(dispatch_get_main_queue(),{
            self.title = self.playlist["name"]
        })
        
        builder.SetupSession(Currentsession!)
       
        builder.GrabTracksFromPlaylist(0, tracksInPlaylist: playlist["total"]?.toInt(), playlist: playlist) { (result) -> () in
            if result != nil && result!.count != 0 {
                self.list = result!
                dispatch_async(dispatch_get_main_queue(),{
                    self.tableView.reloadData()
                })
            }
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
            
            
            //call spotify 
            builder.deleteTrackFromPlaylist(playlist["playlistID"]!, trackURI: trackURI, completionHandler: { result in
                self.tableView.reloadData()
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
}
