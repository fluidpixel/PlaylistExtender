//
//  PlaylistBuilder.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 01/06/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import Foundation


class PlaylistBuilder {
    //MARK: VARIABLES
    var currentSession: SPTSession?
    var PlaylistName: String?
    var playlist_ID : String?
    var PlaylistNewID : String?
    var PlaylistNewName : String?
    
    var artist_Dictionary: [String : String] = [:]
    var currentTracks = [String]()

    var trackDictionary : [String : String] = [:] //uris as both keys and values to thin out any duplicates
    var tracksToAdd = [[String]]()
    var duplicateCounter: [String : Int] = [:]
    
    var instances : Int = 0
    var totalTracksInPlaylist : Int? = 0
    var PlaylistList : SPTPlaylistList?
    var listOfPlaylists = [[String : String]]()

    var finished : Bool = false
    var owner_ID = ""
    var transferTracksOver: Bool = false
    
    var filterExplitives: Bool = false
    var IsExplicit = false
    var resultingArray = [[String]]()

    let clientID: String = "89ce87c720004dcda7261f1c49c15905" //TODO add to defaults

    func SetPlaylistList(list: [[String : String]]){
        listOfPlaylists = list
        
        resultingArray = [[String]]()
    }
    
    func SetupSession(thisSession : SPTSession) {
        currentSession = thisSession
    }
    
    func resetVARS(){
        currentTracks = [String]()
        finished = false
        PlaylistNewName = nil
        PlaylistNewID = nil
        instances = 0
    }
    
    //MARK: FUNCTIONS
    func buildPlaylist(playlist: [String : String], session: SPTSession, sizeToIncreaseBy: Int, name: String?, extendOrBuild: Bool, completionHandler: (result: String?) -> () ) {
        resetVARS()
        currentSession = session
        PlaylistName = playlist["playlistName"]
        PlaylistNewName = name
        //println(playlist.playableUri)
        
        transferTracksOver = extendOrBuild
        
        playlist_ID = playlist["playlistID"]
        
        owner_ID = playlist["ownerID"]!
            
        FindArtists() { result in
            
            if result == true {
                
                self.findPopularSongsByArtist(sizeToIncreaseBy) { result in
                    
                    if result == true {

                        self.CreateNewPlaylist(sizeToIncreaseBy) { result in
                            
                            if result == true {
                                completionHandler(result: self.PlaylistNewID)
                            } else if result == false {
                                completionHandler(result: "429")
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
        
        var playlistName : String = PlaylistName! + " Extended"
        
        if PlaylistNewName != nil && PlaylistNewName != "" {
            playlistName = PlaylistNewName!
        }

        // JSON Body
        
        let bodyObject = [
            "name": "\(playlistName)",
            "public": "false"
        ]
        
        //println(bodyObject)
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1", forHTTPHeaderField: "Retry-After")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        if statusCode != 429 {
                    
                    
                        //println(result)
                        
                        var err : NSError?
                        if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            
                            self.PlaylistNewID = jsonObject.valueForKey("id") as? String
                            
                            if self.PlaylistNewID != nil {
                               
                                self.AddTracks(numbertoAdd) { result in
                                 println("trace - add tracks called")
                                    if result == true {
                                        if self.transferTracksOver == true {
                                            self.CopyOverExistingTracks(0) { result in
                                                if result == true {
                                                    completionHandler(result: true)
                                                    println("trace - finished copying over")
                                                }
                                            }
                                        }else {
                                            println("No need to copy over")
                                            completionHandler(result: true)
                                        }
                                         println("trace - callback received")
                                        
                                    }
                                }
                            }
                        }
                        
                    } else {
                        println(result)
                        completionHandler(result: false)
                        //self.InCaseof429()
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
    //TODO - Add functionality to add more than 100 tracks
    func AddTracks(numberOfTracks: Int, completionHandler: (result: Bool?) -> () ) {
        
        // add tracks to the new playlist here
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        shuffle(tracksToAdd)
            
        var requestArray = [[String]]()
        
        //println(tracksToAdd)
        
        //println(trackDictionary)
        
        //have a normal shuffle then pick X songs by each artist up to Y size of request
        var ratioCounter: [String: Int] = [:]
        var newArray = [String]()
        
        for all in tracksToAdd {
            
            for var i = 1; i < all.count; i++ {
                
                //debug stuff
                var ratio: Double = 1
                
                if duplicateCounter[all[i]] != nil {
                    
                    //println(Double(duplicateCounter[all[i]]!))
                    ratio = (Double(duplicateCounter[all[i]]!) / Double(instances))*100.0
                }
                if (ratioCounter[all[i]] == nil) || Double(ratioCounter[all[i]]!) <= (ratio) {
                    let temp = all[0]
                    if trackDictionary[temp] != nil {
                        
                    }else {
                        if ratioCounter[all[i]] == nil{
                            ratioCounter[all[i]] = 0
                        }
                        ratioCounter[all[i]] = ratioCounter[all[i]]! + 1
                        trackDictionary[temp] = temp
                        if newArray.count <= numberOfTracks {
                            newArray.append(temp)
                        }
                    }
                }
            }
        }
        
        let arrayCount : Int = Int(ceil(Double(newArray.count / 100)))
        
        for var i = 0; i < arrayCount; i++ {
            
        //array start index = i, end index = i + 100 < array.count
            
        //get the relevant range of the array
        
        var endIndex = (i*100 + 100)
            
        if (i*100 + 100) > newArray.count {
            endIndex = newArray.count
        }
            
        let sliceOfArray: [String] = Array(newArray[(i*100)..<endIndex])

        let dict = ["uris" : sliceOfArray]
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists/\(PlaylistNewID!)/tracks?position=0")
        
        let request = NSMutableURLRequest(URL: URL!)
        request.HTTPMethod = "POST"
        
        // JSON Body

        let bodyObject = dict
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1", forHTTPHeaderField: "Retry-After")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                     if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    if statusCode != 429 {
                   
                        println(result)
                        if i == (arrayCount - 1) {
                            completionHandler(result: true)
                        }
                    
                    }else {
                        println(result)
                        //self.InCaseof429()
                         completionHandler(result: false)
                        }
                    }
                }
            }
        })
        task.resume()
        }

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
            
            //println(URL!)
            
            // JSON Body
            
            let bodyObject = dict
            
            //println(bodyObject)
            
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.allZeros, error: nil)
            
            request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("1", forHTTPHeaderField: "Retry-After")
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                if (error == nil) {
                    // Success
                    if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                        println("URL Session Task Succeeded: HTTP \(statusCode), \(offset)")
                        
                        if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            //println(result)
                            if statusCode != 429 {
                                let offset2 : Int = offset + 100
                                
                                if offset2 < self.currentTracks.count {
                                    self.CopyOverExistingTracks(offset2) { result in
                                        if result == true {
                                            completionHandler(result: true)
                                        }
                                    }
                                }else {
                                    
                                    self.finished = true
                                    println("trace - copy over")
                                    completionHandler(result: true)
                                }
                            }else {
                                println(result)
                                //self.InCaseof429()
                                 completionHandler(result: false)
                            }
                        }
                    }
                }
            })
            task.resume()
            
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
        
        var currentOffset = offset
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let user_ID: String = currentSession!.canonicalUsername
        
        //need a catch for when the playlist does not belong to the user
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(owner_ID)/playlists/\(playlist_ID!)/tracks")
        
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
               // request.addValue("1", forHTTPHeaderField: "Retry-After")
                
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
            
           // println(URL!)
            
            request.HTTPMethod = "GET"
            
            request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
          //  request.addValue("1", forHTTPHeaderField: "Retry-After")
            
             dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)) { () -> Void in
            
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
                    if (error == nil) {
                        // Success
                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                            //println("URL Session Task Succeeded: HTTP \(statusCode)")
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
    
    //MARK: Remove individual tracks from playlists
    
    func deleteTrackFromPlaylist(playlist_ID : String, trackURI : String, completionHandler: (result: Bool) -> () ) {
        
        let user_ID: String = currentSession!.canonicalUsername
        
        let array : [String: String] = ["{\"uri\"" : "\"\(trackURI)\"}"]
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists/\(playlist_ID)")

        // JSON Body "{\"tracks\":[{\"uri\":\"\(trackURI)\"}]}"
        
        let bodyObject : [String: [String: String]] = ["\"tracks\"" : array]
    
        println(bodyObject)
        let request = NSMutableURLRequest(URL: URL!)
        
        request.HTTPMethod = "DELETE"
        
        println(NSJSONSerialization.isValidJSONObject(bodyObject))
        
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        
        request.addValue("\(currentSession!.tokenType) \(currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if error == nil {
                
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        println(result)
                    }
                }
            }
        })
        task.resume()

        
    }
    
    //MARK: Grab initial playlistList
    
    func grabUsersListOfPlaylists(offset: Int, thisSession: SPTSession, completionHandler: (result: [[String: String]], playlistCount: Int) -> () ) {
        
        let user_ID: String = thisSession.canonicalUsername
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists")
        
        let URLParams = [
            "limit" : "50",
            "offset" : "\(offset)"
        ]
        
        URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
        
        let request = NSMutableURLRequest(URL: URL!)
        
        request.HTTPMethod = "GET"
        
        println("\(thisSession.tokenType) \n \(thisSession.accessToken)")
        
        request.addValue("\(thisSession.tokenType) \(thisSession.accessToken)", forHTTPHeaderField: "Authorization")
        
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if error == nil {
                
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        //println(result)
                        
                        var resultantArray = [[String: String]]()
                        
                        var err : NSError?
                        if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                            
                            let totalPlaylists: Int = Int((jsonObject.valueForKey("total") as! CLong))
                            
                            if let items : NSArray = jsonObject.valueForKey("items") as? NSArray {
                                
                                for item in items {
                                    
                                    var temp = [String: String]()
                                    
                                    if let track : NSDictionary = item.valueForKey("tracks") as? NSDictionary {
                                        let trackCount : Int = (Int((track.valueForKey("total") as? CLong)!))
                                        if  trackCount > 0 {
                                            
                                            temp["tracksInPlaylist"] = track.valueForKey("total") as? String
                                            
                                            temp["playlistName"] = item.valueForKey("name") as? String
                                            
                                            temp["playlistID"] = item.valueForKey("id") as? String
                                            
                                            if let images: NSArray = item.valueForKey("images") as? NSArray {
                                                
                                                if images.count > 0 {
                                                    temp["smallestImage"] = images[0].valueForKey("url") as? String
                                                }
                                            }
                                            
                                            
                                            
                                            if let owner : NSDictionary = item.valueForKey("owner") as? NSDictionary {
                                                
                                                temp["ownerID"] = owner.valueForKey("id") as? String
                                                
                                            }
                                            resultantArray.append(temp)
                                            
                                        }
                                    }
                                }
                                completionHandler(result: resultantArray, playlistCount: totalPlaylists)
                            }
                        }
                    }
                }
            }
        })
        task.resume()
        
    }

        //MARK: Functions used to display tracks
    func GrabTracksFromPlaylist(offset : Int, tracksInPlaylist : Int?, playlist : [String : String], completionHandler: (result: [[String]]?) -> () ) {
        
        let playlist_ID = playlist["playlistID"]!
        
        let owner_ID = playlist["ownerID"]!
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let user_ID: String  = currentSession!.canonicalUsername
        
        println(playlist_ID)
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(owner_ID)/playlists/\(playlist_ID)/tracks")
        
            let URLParams = [
                "offset": "\(offset)",
            ]
            
            URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
            
            let request = NSMutableURLRequest(URL: URL!)
            
            request.HTTPMethod = "GET"
        
            println("\(currentSession!.tokenType) \n \(currentSession!.accessToken)")
            
            request.addValue("\(currentSession!.tokenType) \(currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
                if error == nil {
                    
                    if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                        
                        println("URL Session Task Succeeded: HTTP \(statusCode)")
                        
                        if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            //println(result)
                            
                            //add results into array
                            
                            var err : NSError?
                            if let jsonObject : NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSDictionary {
                                
                                if let tracks: NSArray = jsonObject.valueForKey("items") as? NSArray {
                                    
                                    //sort results into a list of names, artists and length(?)
                                    
                                    for all in tracks {
                                        
                                        var tempArray = [String]()
                                        
                                        if let individual: NSDictionary = all.valueForKey("track") as? NSDictionary {
                                        
                                            tempArray.append(individual.valueForKey("name") as! String)
                                            
                                            if let album = individual.valueForKey("album") as? NSDictionary {
                                                
                                                if let images = album.valueForKey("images") as? NSArray {
                                                    tempArray.append(images[2].valueForKey("url") as! String)
                                                }
                                            }
                                            
                                            tempArray.append(String(format: "%5.2f", (((individual.valueForKey("duration_ms"))!.doubleValue) / 60000.0)))
                                            
                                            tempArray.append(individual.valueForKey("uri") as! String)
                                            
                                            if let artists = individual.valueForKey("artists") as? NSArray {

                                                for art in artists {
                                                    
                                                     tempArray.append(art.valueForKey("name") as! String)
                                                }
                                            }
                                            
                                            self.resultingArray.append(tempArray)
                                        }
                                    }
                                    let offset2 = offset + 100
                                    if offset2 < tracksInPlaylist {
                                        
                                        
                                        self.GrabTracksFromPlaylist(offset2, tracksInPlaylist: tracksInPlaylist, playlist: playlist, completionHandler: { (result) -> () in
                                            
                                            if result != nil && result!.count > 0 {
                                                completionHandler(result: result)
                                            }
                                        })
                                        
                                    } else {
                                        completionHandler(result: self.resultingArray)
                                    }
                                }
                            }
                        }
                    }
                }
            })
            task.resume()
    }

    //MARK: Helper functions
    func SortResultsIntoArray(object : NSDictionary) {
        
        if let tracks: [NSDictionary] = object.valueForKey("tracks") as? [NSDictionary] {
            
            for all in tracks {
                
                if let artists = all.valueForKey("artists") as? NSArray {
                    var counter = 1
                    for art in artists {
                        var index = 0
                        if (tracksToAdd.count-1) > 0 {
                            index = tracksToAdd.count-1
                        }else {
                            index = 0
                        }
                        
                        if tracksToAdd.count == 0 {
                            tracksToAdd.append([all.valueForKey("uri") as! String, art.valueForKey("id") as! String])
                            
                        } else if tracksToAdd[index][0] != all.valueForKey("id") as! String {
                            tracksToAdd.append([all.valueForKey("uri") as! String, art.valueForKey("id") as! String])
                            
                        } else {
                            tracksToAdd[tracksToAdd.count-1].append(art.valueForKey("id") as! String)
                        }
                        counter++
                    }
                }
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
                        
                        IsExplicit = track.valueForKey("explicit") as! Bool
                        
                        trackDictionary[track.valueForKey("uri") as! String] = (track.valueForKey("uri") as! String)
                        
                        if let artists = track["artists"] as? NSArray {
                            
                            for i in artists {
                                
                                if i.valueForKey("id") as? String != nil {
                                    
                                    //if !IsExplicit || !filterExplitives{
                                    instances++
                                    artist_Dictionary[i.valueForKey("name") as! String] = i.valueForKey("id") as? String
                                    //trackMap[currentTracks[currentTracks.count-1]] = trackMap[currentTracks[currentTracks.count-1]]!.append(i.valueForKey("name") as? String)
                                    //add count to dupes if an artist dupe
                                    if duplicateCounter[i.valueForKey("id") as! String] == nil {
                                        duplicateCounter[i.valueForKey("id") as! String] = 1
                                    } else {
                                        let counter = duplicateCounter[i.valueForKey("id") as! String]
                                        duplicateCounter[i.valueForKey("id") as! String] = (counter! + 1)
                                    }
                                    //}
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
    
    func InCaseof429() {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let user_ID: String = currentSession!.canonicalUsername
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists/\(playlist_ID!)/followers")
        
        let request = NSMutableURLRequest(URL: URL!)
        
        // println(URL!)
        
        request.HTTPMethod = "DELETE"
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    println("URL Session Task Succeeded: HTTP \(statusCode)")
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        //println(result)
                        
                    }
                }
                
            }
        })
        task.resume()
        
    }



}