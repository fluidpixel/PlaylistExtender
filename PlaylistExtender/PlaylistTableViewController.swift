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
    var playlist : SPTPartialPlaylist?
    var Currentsession : SPTSession?
    var list = [[String]]()
    
    override func viewDidLoad() {
        
        builder.SetupSession(Currentsession!)
        self.tableView.reloadData()
        builder.GrabTracksFromPlaylist(0, tracksInPlaylist: Int(playlist!.trackCount), playlist: playlist!) { (result) -> () in
            
            if result != nil && result!.count != 0 {
                self.list = result!
                self.tableView.reloadData()
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if playlist != nil {
            return Int(playlist!.trackCount)
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell") as! UITableViewCell
        var artistText = ""
        if list.count > 0  {
            cell.textLabel?.text = "\(list[indexPath.row][0])"
            
            for var i = 2; i < list[indexPath.row].count; i++ {
                if i != 2 {
                    artistText = artistText + ", "
                }
                artistText = artistText + " \(list[indexPath.row][i])"
            }
            
            cell.detailTextLabel?.text = " \(artistText) - \(list[indexPath.row][1])"
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }
}
