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
    var PlaylistName: String?
    var playlist_ID : String?
    var artist_Dictionary: [String : String] = [:]
    var totalTracksInPlaylist : Int? = 0
    var PlaylistList : SPTPlaylistList?
    var PlaylistNewID : String?
    
    var currentTracks = [String]()
    
    let clientID: String = "89ce87c720004dcda7261f1c49c15905" //TODO add to defaults
    
    var tracksToAdd = [String]()
    
    func SetPlaylistList(list: SPTPlaylistList){
        PlaylistList = list
    }
    
    func buildPlaylist(playlist: SPTPartialPlaylist, session: SPTSession, sizeToIncreaseBy: Int, completionHandler: (result: Bool?) -> () ){
        
        currentSession = session
        PlaylistName = playlist.name
        println(playlist.playableUri)
        
        let array = split("\(playlist.uri)") {$0 == ":"}
        playlist_ID = array[(array.count-1)]
            
        FindArtists() { result in
            
            if result == true {
                
                self.findPopularSongsByArtist(sizeToIncreaseBy) { result in
                    
                    if result == true {
                        //create new playlist and add songs to it, along with current songs on the playlist
                        
                        self.CreateNewPlaylist(sizeToIncreaseBy) { result in
                            
                            if result == true {
                                completionHandler(result: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func CreateNewPlaylist(numbertoAdd: Int, completionHandler: (result: Bool?) -> () ) {

        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists")
        
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        let playlistName : String = PlaylistName! + " Extended 2"
        
        // JSON Body
        
        let bodyObject = [
            "name": "\(playlistName)",
            "public": "false"
        ]
        
        println(bodyObject)
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        println(result)
                        
                        var err : NSError?
                        if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            
                            self.PlaylistNewID = jsonObject.valueForKey("id") as? String
                            
                            if self.PlaylistNewID != nil {
                                self.AddTracks(numbertoAdd) { result in
                                
                                    if result == true {
                                        completionHandler(result: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else {
                // Failure
                println("URL Session Task Failed: %@", error.localizedDescription);
            }
        })
        task.resume()
    }
    
    func AddTracks(numberOfTracks: Int, completionHandler: (result: Bool?) -> () ) {
        
        // add tracks to the new playlist here
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        shuffle(tracksToAdd)
        
        var newArray = [String]()
        
        for var i = 0; i < numberOfTracks && i < tracksToAdd.count; i++ {
            
            newArray.append(tracksToAdd[i])
           
        }
        
        let dict = ["uris" : newArray]
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists/\(PlaylistNewID!)/tracks?position=0")
        
       // URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: dict)
        
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        println(URL!)
        
        // JSON Body

        let bodyObject = dict
        
        println(bodyObject)
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        println(result)
                        
                        self.CopyOverExistingTracks(0) { result in
                            if result == true {
                                completionHandler(result: true)
                            }
                        }
                        //var err : NSError?
                        //if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                        //}
                    }
                }
            }
        })
        task.resume()

    }
    
    func CopyOverExistingTracks(offset: Int, completionHandler: (result: Bool?) -> () ) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        var offsetted = [String]()
        
        if offset < currentTracks.count {
            
            if offset + 100 < currentTracks.count {
                let add = offset + 100
                 offsetted = Array(currentTracks[offset..<add])
            } else {
                
                offsetted = Array(currentTracks[offset..<currentTracks.count])
            }

            let dict : [ String: [String]] = ["uris" : offsetted]
            
            var URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists/\(PlaylistNewID!)/tracks?position=0")
            
            // URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: dict)
            
            let request = NSMutableURLRequest(URL: URL!)
            request.HTTPMethod = "POST"
            
            println(URL!)
            
            // JSON Body
            
            let bodyObject = dict
            
            println(bodyObject)
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
            
            request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                if (error == nil) {
                    // Success
                    if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                        println("URL Session Task Succeeded: HTTP \(statusCode)")
                        
                        if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            println(result)
                            
                            let offset2 : Int = offset + 100
                            
                            if offset2 < self.currentTracks.count {
                                self.CopyOverExistingTracks(offset2) { result in }
                            }
                            
                            //var err : NSError?
                            //if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            //}
                        }
                    }
                }
            })
            task.resume()
            
        }else {
            completionHandler(result: true)
        }
    }
    
    func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let c = count(list)
        for i in 0..<(c - 1) {
            let j = Int(arc4random_uniform(UInt32(c - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
    
    
    private func FindArtists(offset : Int = 0, completionHandler: (result: Bool?) -> () ){
        
        //YES IT WORKS
        
        var currentOffset = offset
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let user_ID: String = currentSession!.canonicalUsername
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
        
        var counter = 0
        
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
                                //println(result)
                                
                            }
                        }
                        
                        var err : NSError?
                        if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            //sort this into an array
                             counter++
                            self.SortResultsIntoArray(jsonObject)
                            if counter >= self.artist_Dictionary.count {
                                completionHandler(result: true)
                            }
                            
                        }
                        
                    }
            
                })
                task.resume()

            }
        }
    }

    func SortResultsIntoArray(object : NSDictionary) {
        
        if let tracks: [NSDictionary] = object.valueForKey("tracks") as? [NSDictionary] {
            
            for all in tracks {
                
                tracksToAdd.append(all.valueForKey("uri") as! String)
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
                        
                        currentTracks.append(track.valueForKey("uri") as! String)
                        
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