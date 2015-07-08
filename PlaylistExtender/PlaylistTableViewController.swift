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
        
        
        dispatch_async(dispatch_get_main_queue(),{
            self.title = self.playlist?.name
        })
        
        builder.SetupSession(Currentsession!)
       
        builder.GrabTracksFromPlaylist(0, tracksInPlaylist: Int(playlist!.trackCount), playlist: playlist!) { (result) -> () in
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("TrackCell") as! CustomTableViewCell
        
        //todo - add image
        
        
        
        var artistText = ""
        if list.count > 0  {
            cell.ApplyImage("\(list[indexPath.row][1])")
            cell.Title.text = "\(list[indexPath.row][0])"
            
            for var i = 3; i < list[indexPath.row].count; i++ {
                if i != 3 {
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
