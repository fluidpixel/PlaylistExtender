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
    var playlist_ID : String?
    var artist_Dictionary: [String : String] = [:]
    var totalTracksInPlaylist : Int? = 0
    
    let clientID: String = "89ce87c720004dcda7261f1c49c15905" //TODO add to defaults
    
    var tracksToAdd = [String]()
    
    func buildPlaylist(playlist: SPTPartialPlaylist, session: SPTSession, sizeToIncreaseBy: Int){
        
        currentSession = session
        
        println(playlist.playableUri)
        
        let array = split("\(playlist.uri)") {$0 == ":"}
        playlist_ID = array[(array.count-1)]
            
        FindArtists() { result in
            
            if result == true {
                
                self.findPopularSongsByArtist(sizeToIncreaseBy) { result in
                    
                    if result == true {
                        //create new playlist and add songs to it, along with current songs on the playlist
                    }
                    
                }
            }
            
            
        }
        
        
        
    }
    
    private func FindArtists(offset : Int = 0, completionHandler: (result: Bool?) -> () ){
        
        //YES IT WORKS
        
        var currentOffset = offset
//        
//        if !(currentSession!.isValid()) {
//            
//            SPTAuth.defaultInstance().renewSession(currentSession, callback: { (error: NSError!, session: SPTSession!) -> Void in
//                
//                if error == nil {
//                    self.currentSession = session
//                }
//            })
//        }
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        //let playlist_ID: String = playlist.snapshotId
        
        let user_ID: String = currentSession!.canonicalUsername
        
        var temp = 0
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists/\(playlist_ID!)/tracks")
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)) { () -> Void in
                
                let URLParams = [
                    "offset": "\(offset)",
                ]
                
                URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
                
                println(URL!)
                
                let request = NSMutableURLRequest(URL: URL!)
                
                request.HTTPMethod = "GET"
                
                //headers
                println(self.currentSession!.accessToken)
                println(self.currentSession!.tokenType)
                println(self.currentSession!.expirationDate)
                
                request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
                
                //limits at 100 per grab, so will need to repeat grab until grabbed entire playlist
                //just grab artists to minimize size of array?
                
                /* Start a new Task */
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                    if (error == nil) {
                        // Success
                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                            println("URL Session Task Succeeded: HTTP \(statusCode)")
                            
                            if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                                //println(result)
                                
                            }
                            //omg that's a lot of data to parse through
                            var err : NSError?
                            if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                                
                                self.SortResultIntoDictionary(jsonObject)
                                
                                currentOffset = offset + 100
                                
                                if currentOffset < self.totalTracksInPlaylist {
                                    self.FindArtists(offset: currentOffset, completionHandler: completionHandler)
                                } else {
                                    completionHandler(result: true)
                                }
                                
                            }else {
                                println(err?.localizedDescription)
                            }
                        }
                    } else {
                        // Failure
                        println("URL Session Task Failed: %@", error.localizedDescription);
                    }
                })
                task.resume()
            }
        
    }
    
    private func findPopularSongsByArtist(numberofsongs: Int, completionHandler: (result: Bool?) -> () ) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let market = "GB"
        
        for (key, value) in artist_Dictionary {
        
            var URL = NSURL(string: "https://api.spotify.com/v1/artists/\(value)/top-tracks")
            
            let URLParams = [
                "country": "\(market)",
            ]
            
            URL = NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
            
            let request = NSMutableURLRequest(URL: URL!)
            
            println(URL!)
            
            request.HTTPMethod = "GET"
            
            request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            
             dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)) { () -> Void in
            
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                    if (error == nil) {
                        // Success
                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                            println("URL Session Task Succeeded: HTTP \(statusCode)")
                            if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                                println(result)
                                
                            }
                        }
                        
                        var err : NSError?
                        if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            //sort this into an array
                            
                            self.SortResultsIntoArray(jsonObject)
                        }
                        
                    }
            
                })
                task.resume()

            }
        }
    }
    
    func CreateNewPlaylist() {
        
    }
    
    func SortResultsIntoArray(object : NSDictionary) {
        
        if let tracks: NSDictionary = object.valueForKey("tracks") as? NSDictionary {
            
            for (key, value) in tracks {
                
                tracksToAdd.append(object.valueForKey("uri") as! String)
            }

        }
        
        
    }
    
    func SortResultIntoDictionary(object : NSDictionary) {
        // take artist ID and name in dictionary
        for (key, value) in object {
            
            totalTracksInPlaylist = object.valueForKey("total") as? Int
            
            if let trackArray = object.valueForKey(key as! String) as? NSArray {
                for values in trackArray{
                    
                    if let track: NSDictionary = values["track"] as? NSDictionary {
                        
                        if let artists = track["artists"] as? NSArray {
                            
                            for i in artists {
                                
                                if i.valueForKey("id") as? String != nil {
                                    
                                    artist_Dictionary[i.valueForKey("name") as! String] = i.valueForKey("id") as? String
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func NSURLByAppendingQueryParameters(URL : NSURL!, queryParameters : Dictionary<String, String>) -> NSURL {
        let URLString : NSString = NSString(format: "%@?%@", URL.absoluteString!, self.stringFromQueryParameters(queryParameters))
        return NSURL(string: URLString as String)!
    }
    
    func stringFromQueryParameters(queryParameters : Dictionary<String, String>) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            var part = NSString(format: "%@=%@",
                name.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!,
                value.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
            parts.append(part as String)
        }
        return "&".join(parts)
    }
    
        




}