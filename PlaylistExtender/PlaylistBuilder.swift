//
//  PlaylistBuilder.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 01/06/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import Foundation

class PlaylistBuilder {
    
    var currentSession: SPTSession?
    var playlistSnapshot : SPTPlaylistSnapshot?
    
    var tracksToAdd: [SPTTrack]?
    
    func buildPlaylist(playlist: SPTPartialPlaylist, session: SPTSession){
        
        SPTPlaylistSnapshot.playlistWithURI(playlist.uri!, session: session) { (error: NSError!, callback: AnyObject!) -> Void in
            
            if error != nil {
                println("failed to parse playlist snapshot, error: \(error.description)")
            }
            self.playlistSnapshot = callback as? SPTPlaylistSnapshot
            
            //grab a page of songs from the playlist
            if let itemsOfPage: [AnyObject] = self.playlistSnapshot?.firstTrackPage.items {
                
                for item in itemsOfPage {
                    
                    if let track : SPTTrack = item as? SPTTrack {
                        
                        if let artists: [SPTArtist] = track.artists as? [SPTArtist] {
                            self.findPopularSongsByArtist(artists) { result in
                                
                                if result != nil {
                                    self.playlistSnapshot?.addTracksToPlaylist(self.tracksToAdd!, withSession: session, callback: { (error: NSError!) -> Void in
                                        
                                        if error != nil {
                                            println("\(error.description)")
                                        }
                                        
                                    })
                                }
                            }
                        }
                        
                    }
                }
                
            }

        }
            
        
        
    }
    
    
        


    private func findPopularSongsByArtist(artists: [SPTArtist?], completionHandler: (result: Bool?) -> () ) {
        var complete: Bool? = nil
        for art in artists {
            
            art?.requestTopTracksForTerritory("GB", withSession: currentSession, callback: { (error: NSError!, callback: AnyObject!) -> Void in
                
                if error != nil {
                    println("\(error.description)")
                  
                } else {
                    if let tracks : [SPTTrack] = callback as? [SPTTrack] {
                        
                        self.tracksToAdd?.extend(tracks)
                        complete = true
                    }else {
                        println("could not parse track")
                    }
                }
            })
        }
        
        completionHandler(result: complete)
}

}