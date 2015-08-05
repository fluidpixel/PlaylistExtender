
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
    var resultingArray = [[String]]()

    let clientID: String = "89ce87c720004dcda7261f1c49c15905" //TODO add to defaults
    
    var completionLogger = [Int : Bool]()

    func SetPlaylistList(list: [[String : String]]){
        listOfPlaylists = list
        
        resultingArray = [[String]]()
    }
    
    func SetupSession(thisSession : SPTSession) {
        currentSession = thisSession
    }
    
    func resetVARS(){
        currentTracks = [String]()
        completionLogger = [Int : Bool]()
        finished = false
        PlaylistNewName = nil
        PlaylistNewID = nil
        instances = 0
    }
    
    //MARK: FUNCTIONS
    func buildPlaylist(playlist: [String : String], session: SPTSession, sizeToIncreaseBy: Int, name: String?, extendOrBuild: Bool, filter : Bool, completionHandler: (result: String?) -> () ) {
        resetVARS()
        currentSession = session
        PlaylistName = playlist["playlistName"]
        PlaylistNewName = name
        filterExplitives = filter
        
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

        let URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists")
        
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
        
        do {
            //println(bodyObject)
        
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions())
        } catch _ {
            request.HTTPBody = nil
        }
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("1", forHTTPHeaderField: "Retry-After")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    let data = data!
                    
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                        if statusCode != 429 {
                            do {
                                if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                                    
                                    self.PlaylistNewID = jsonObject.valueForKey("id") as? String
                                    
                                    if self.PlaylistNewID != nil {
                                        
                                        self.AddTracksManager(numbertoAdd) { result in
                                            print("trace - add tracks called")
                                            if result == true {
                                                if self.transferTracksOver == true {
                                                    self.CopyOverExistingTracks(0) { result in
                                                        if result == true {
                                                            completionHandler(result: true)
                                                            print("trace - finished copying over")
                                                        }else if result == false {
                                                            print("429 error")
                                                            completionHandler(result: false)
                                                        }
                                                    }
                                                }else {
                                                    print("No need to copy over")
                                                    completionHandler(result: true)
                                                }
                                                print("trace - callback received")
                                            }
                                        }
                                    }
                                } else {
                                    print(result)
                                    
                                    usleep(5000)
                                    
                                    self.CreateNewPlaylist(numbertoAdd, completionHandler: { (result) -> () in
                                        
                                        if result == true {
                                            completionHandler(result: true)
                                        }
                                    })
                                    
                                    //completionHandler(result: false)
                                    //self.InCaseof429()
                                }
                            } catch {
                                print("ERROR")
                                //                            print("URL Session Task Failed: %@", error.localizedDescription);
                            }
                        
                        }
                }
            }
            }
        })
        task.resume()
    }
    //TODO - Add functionality to add more than 100 tracks
    func AddTracksManager(numberOfTracks: Int, completionHandler: (result: Bool?) -> () ) {
        
        // add tracks to the new playlist here
        shuffle(tracksToAdd)
            
//        let requestArray = [[String]]()
        
        //have a normal shuffle then pick X songs by each artist up to Y size of request
        var ratioCounter: [String: Int] = [:]
        var newArray = [String]()
        
        for all in tracksToAdd {
            
            for var i = 1; i < all.count; i++ {
                
                //debug stuff
                var ratio: Double = 1
                
                if duplicateCounter[all[i]] != nil {
                    
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
        
        //split this into two mthods
        AddTracksPoster(0,total: numberOfTracks, newArray: newArray) { result in
            
            completionHandler(result: result)
        }
        
    }
    
    func AddTracksPoster(offset: Int, total: Int, newArray: [String], completionHandler: (result: Bool?) -> () ) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
//        let arrayCount  = ceil((Double(newArray.count) / 100.0))
//        let convertToInt : Int = Int(arrayCount)
        
        //for var i = 0; i < convertToInt; i++ {
            
            //array start index = i, end index = i + 100 < array.count
            //get the relevant range of the array
        
    
            var endIndex = (offset + 100)
            
            if endIndex > newArray.count {
                endIndex = newArray.count
            }
            
            let sliceOfArray: [String] = Array(newArray[offset..<endIndex])
            let dict = ["uris" : sliceOfArray]
            
            let URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists/\(PlaylistNewID!)/tracks?position=0")
            let request = NSMutableURLRequest(URL: URL!)
            request.HTTPMethod = "POST"
            
            // JSON Body
            
            let bodyObject = dict
            do {
                request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions())
            } catch _ {
                request.HTTPBody = nil
            }
            
            request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("1", forHTTPHeaderField: "Retry-After")
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
                if (error == nil) {
                    // Success
                    let data = data!
                    if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                        print("URL Session Task Succeeded: HTTP \(statusCode)")
                        if let result = NSString(data: data, encoding: NSUTF8StringEncoding) {
                            if statusCode != 429 {
                                
                                print(result)
                                let offset2 = offset + 100
                                if offset2 >= (total) {
                                    completionHandler(result: true)
                                } else {
                                    
                                    if offset2 < total {
                                        self.AddTracksPoster(offset2, total: total, newArray: newArray, completionHandler: { (result) -> () in
                                        
                                            completionHandler(result: result)
                                        })
                                    }
                                }
                                
                            }else if statusCode == 429 {
                                
                                usleep(5000)
                                if offset + 100 < total {
                                    self.AddTracksPoster(offset, total: total, newArray: newArray) { result in
                                        if result == true {
                                            completionHandler(result: true)
                                        }
                                    }
                                }
                            }else {
                                completionHandler(result: false)
                                
                            }

                        }
                    }
                }
            })
            task.resume()
        //}
        
    }
    
    func CopyOverExistingTracks(offset: Int, completionHandler: (result: Bool?) -> () ) {
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        var offsetted = [String]()
        
        var usableOffset = offset
        
        if usableOffset < currentTracks.count {
            
            if completionLogger[usableOffset] != true {
            
                if usableOffset + 100 < currentTracks.count {
                    let add = usableOffset + 100
                     offsetted = Array(currentTracks[usableOffset..<add])
                } else {
                    offsetted = Array(currentTracks[usableOffset..<currentTracks.count])
                }

                let dict : [ String: [String]] = ["uris" : offsetted]
                
                let URL = NSURL(string: "https://api.spotify.com/v1/users/\(currentSession!.canonicalUsername)/playlists/\(PlaylistNewID!)/tracks?position=0")
                
                // URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: dict)
                
                let request = NSMutableURLRequest(URL: URL!)
                request.HTTPMethod = "POST"
                
                // JSON Body
                
                let bodyObject = dict
                
                do {
                    //println(bodyObject)
                
                    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions())
                } catch _ {
                    request.HTTPBody = nil
                }
                
                request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("1", forHTTPHeaderField: "Retry-After")
                
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
                    if (error == nil) {
                        // Success
                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                            print("URL Session Task Succeeded: HTTP \(statusCode), \(offset)")
                            
                            if let _ = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                                //println(result)
                                if statusCode != 429 {
                                    let offset2 : Int = usableOffset + 100
                                    self.completionLogger[usableOffset] = true
                                    if offset2 < self.currentTracks.count {
                                        self.CopyOverExistingTracks(offset2) { result in
                                            if result == true {
                                                completionHandler(result: true)
                                            }
                                        }
                                    }else {
                                        
                                        self.finished = true
                                        print("trace - copy over")
                                        completionHandler(result: true)
                                    }
                                }else if statusCode == 429 {
                                    
                                    usleep(5000)
                                    
                                    self.CopyOverExistingTracks(usableOffset) { result in
                                        if result == true {
                                            completionHandler(result: true)
                                        }
                                    }
                                }else {
                                    completionHandler(result: false)
                                    
                                }
                            }
                        }
                    }
                })
                task.resume()
                
            }else {
                usableOffset = usableOffset + 100
            }
        }
        
    }
    
    func shuffle<C: MutableCollectionType where C.Index == Int>(var list: C) -> C {
        let c = list.count
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
        
//        let user_ID: String = currentSession!.canonicalUsername
        
        //need a catch for when the playlist does not belong to the user
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(owner_ID)/playlists/\(playlist_ID!)/tracks")
        
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)) { () -> Void in
                
                let URLParams = [
                    "offset": "\(offset)",
                ]
                
                URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
                
                print(URL!)
                
                let request = NSMutableURLRequest(URL: URL!)
                
                request.HTTPMethod = "GET"
                
                //headers
                print(self.currentSession!.accessToken)
                print(self.currentSession!.tokenType)
                print(self.currentSession!.expirationDate)
                
                request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("1", forHTTPHeaderField: "Retry-After")
                
                //limits at 100 per grab, so will need to repeat grab until grabbed entire playlist
                //just grab artists to minimize size of array?
                
                /* Start a new Task */
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
                    if (error == nil) {
                        // Success
                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                            print("URL Session Task Succeeded: HTTP \(statusCode)")
                            
//                            if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
//                                //println(result)
//                            }
                            //omg that's a lot of data to parse through
                            
                            do {
                            if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                                
                                self.SortResultIntoDictionary(jsonObject)
                                currentOffset = offset + 100
                                
                                if currentOffset < self.totalTracksInPlaylist {
                                    self.FindArtists(currentOffset, completionHandler: completionHandler)
                                } else {
                                    completionHandler(result: true)
                                }
                                
                            }else {
                                print("error")
                            }
                            
                        }catch {
                            print("error")
                        }
                        }
                    } else {
                        // Failure
                        print("URL Session Task Failed: %@", error!.localizedDescription);
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
        
        for (_, value) in artist_Dictionary {
        
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
            
             dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)) { () -> Void in
            
                let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
                    if (error == nil) {
                        // Success
//                        if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
//                            //println("URL Session Task Succeeded: HTTP \(statusCode)")
//                            if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
//                                //println(result)
//                                
//                            }
//                        }
                        
                        do {
                        if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                            
                            //sort this into an array
                             counter++
                            self.SortResultsIntoArray(jsonObject)
                            if counter >= self.artist_Dictionary.count {
                                completionHandler(result: true)
                            }
                            
                        }
                        
                        } catch {
                            print("error")
                        }
                        
                    }
            
                })
                task.resume()
            }
        }
    }
    
    //MARK: Remove individual tracks from playlists
    
    func deleteTrackFromPlaylist(playlist_ID : String, trackURI : String, pos : Int, completionHandler: (result: Bool) -> () ) {
        
        let user_ID: String = currentSession!.canonicalUsername
        
//        let array : [String: String] = ["\"positions\"" : "[\(pos)]", "\"uri\"" : "\"\(trackURI)\""]
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
        let URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists/\(playlist_ID)")
        
        let bodyObject = ["\"tracks\"" :[
            
            "\"positions\"" : "[\(pos)]",
            "\"uri\"" : "\"\(trackURI)\""
                ]
            ]
    
        print(bodyObject)
        let request = NSMutableURLRequest(URL: URL!)
        
        request.HTTPMethod = "DELETE"
        
        print(NSJSONSerialization.isValidJSONObject(bodyObject))
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(bodyObject, options: NSJSONWritingOptions())
        } catch _ {
            request.HTTPBody = nil
        }
        
        request.addValue("\(currentSession!.tokenType) \(currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if error == nil {
                
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    
                    if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                        print(result)
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
        
        print("\(thisSession.tokenType) \n \(thisSession.accessToken)")
        
        request.addValue("\(thisSession.tokenType) \(thisSession.accessToken)", forHTTPHeaderField: "Authorization")
        
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if error == nil {
                
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
                    
//                    if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                        //println(result)
                        
                        var resultantArray = [[String: String]]()
                    
                    do {
                        if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                            
                            let totalPlaylists: Int = Int((jsonObject.valueForKey("total") as! CLong))
                            
                            if let items : NSArray = jsonObject.valueForKey("items") as? NSArray {
                                
                                for item in items {
                                    
                                    var temp = [String: String]()
                                    
                                    if let track : NSDictionary = item.valueForKey("tracks") as? NSDictionary {
                                        let trackCount : Int = (Int((track.valueForKey("total") as? CLong)!))
                                        if  trackCount > 0 {
                                            
                                            temp["tracksInPlaylist"] = "\(trackCount)"
                                            
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
                    }catch {
                        print("error")
                    }
                    }
                }
//            }
        })
        task.resume()
        
    }

        //MARK: Functions used to display tracks
    func GrabTracksFromPlaylist(offset : Int, tracksInPlaylist : Int?, playlist : [String : String], completionHandler: (result: [[String]]?) -> () ) {
        
        let playlist_ID = playlist["playlistID"]!
        
        let owner_ID = playlist["ownerID"]!
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        
//        let user_ID: String  = currentSession!.canonicalUsername
        
        print(playlist_ID)
        
        var URL = NSURL(string: "https://api.spotify.com/v1/users/\(owner_ID)/playlists/\(playlist_ID)/tracks")
        
            let URLParams = [
                "offset": "\(offset)",
            ]
            
            URL = self.NSURLByAppendingQueryParameters(URL, queryParameters: URLParams)
            
            let request = NSMutableURLRequest(URL: URL!)
            
            request.HTTPMethod = "GET"
        
            print("\(currentSession!.tokenType) \n \(currentSession!.accessToken)")
            
            request.addValue("\(currentSession!.tokenType) \(currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                if error == nil {
                    
                    if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                        
                        print("URL Session Task Succeeded: HTTP \(statusCode)")
                        
//                        if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
                            //println(result)
                            
                            //add results into array
                        do {
                            if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary {
                                
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
                    } catch {
                        print("error")
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
                
                let IsExplicit = all.valueForKey("explicit") as! Bool
                
                if !IsExplicit || !filterExplitives{
                
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
    }
    
    func SortResultIntoDictionary(object : NSDictionary) {
        // take artist ID and name in dictionary
        for (key, _) in object {
            
            totalTracksInPlaylist = object.valueForKey("total") as? Int
            
            if let trackArray = object.valueForKey(key as! String) as? NSArray {
                for values in trackArray{
                    
                    if let track: NSDictionary = values["track"] as? NSDictionary {
                        
                        currentTracks.append(track.valueForKey("uri") as! String)
                        
                        trackDictionary[track.valueForKey("uri") as! String] = (track.valueForKey("uri") as! String)
                        
                        if let artists = track["artists"] as? NSArray {
                            
                            for i in artists {
                                
                                if i.valueForKey("id") as? String != nil {
                                    
                                    instances++
                                    artist_Dictionary[i.valueForKey("name") as! String] = i.valueForKey("id") as? String

                                    //add count to dupes if an artist dupe
                                    if duplicateCounter[i.valueForKey("id") as! String] == nil {
                                        duplicateCounter[i.valueForKey("id") as! String] = 1
                                    } else {
                                        let counter = duplicateCounter[i.valueForKey("id") as! String]
                                        duplicateCounter[i.valueForKey("id") as! String] = (counter! + 1)
                                    }
                                    
                                }
                            }
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func NSURLByAppendingQueryParameters(URL : NSURL!, queryParameters : Dictionary<String, String>) -> NSURL {
        let URLString : NSString = NSString(format: "%@?%@", URL.absoluteString, self.stringFromQueryParameters(queryParameters))
        return NSURL(string: URLString as String)!
    }
    
    func stringFromQueryParameters(queryParameters : Dictionary<String, String>) -> String {
        var parts: [String] = []
        for (name, value) in queryParameters {
            let part = NSString(format: "%@=%@",
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
        
        let URL = NSURL(string: "https://api.spotify.com/v1/users/\(user_ID)/playlists/\(playlist_ID!)/followers")
        
        let request = NSMutableURLRequest(URL: URL!)
        
        // println(URL!)
        
        request.HTTPMethod = "DELETE"
        
        request.addValue("\(self.currentSession!.tokenType) \(self.currentSession!.accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data : NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if (error == nil) {
                // Success
                if let statusCode = (response as? NSHTTPURLResponse)?.statusCode {
                    print("URL Session Task Succeeded: HTTP \(statusCode)")
//                    if let result = NSString(data: data!, encoding: NSUTF8StringEncoding) {
//                        //println(result)
//                        
//                    }
                }
                
            }
        })
        task.resume()
        
    }



}