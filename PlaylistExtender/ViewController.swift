//
//  ViewController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 28/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let clientID: String = "89ce87c720004dcda7261f1c49c15905"
    let clientSecret: String = "5e0e325e2b1f4dc093bfc0c2fdaefc8d"
    let Callback = NSURL(string: "playlistextenderlogin://callback")!
    let kTokenSwapURL = NSURL(string: "http://localhost:1234/swap")!
    let kTokenRefreshURL = NSURL(string: "http://localhost:1234/refresh")!
    let scope: AnyObject = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthPlaylistReadPrivateScope]
    let response: String = "code"
    
    var session : SPTSession!

    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "LoginReceived", name: "LoginSuccessful", object: nil)

    }
    
    func LoginReceived () {
        
         let userDefaults = NSUserDefaults.standardUserDefaults()
        if let sessionObj: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("session_enabled") {
            
            let sessionDataObj = sessionObj as! NSData
            let session = NSKeyedUnarchiver.unarchiveObjectWithData(sessionDataObj) as! SPTSession
            
            if !session.isValid() {
                SPTAuth.defaultInstance().renewSession(session, callback: { (error: NSError!, session: SPTSession!) -> Void in
                    if error == nil {
                        let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                        
                        userDefaults.setObject(sessionData, forKey: "session_enabled")
                        userDefaults.synchronize()
                        
                        self.session = session
                        
                    } else {
                        println("error refreshing session")
                    }
                })
            } else {
                println("session is valid")
                
                self.session = session
                self.performSegueWithIdentifier("LoginReceived", sender: session)
            }
            println("YAY SUCCESS")
        } else {
            loginButton.hidden = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //any pre-segue stuff goes in here
	if let navigation = segue.destinationViewController as? UINavigationController {
		if let pc = navigation.viewControllers.first as? PlaylistController {
			if (sender as! SPTSession).isValid() {
				pc.session = (sender as! SPTSession)
			}
		}
	}
//        if let pc = segue.destinationViewController as? PlaylistController {
//            if (sender as! SPTSession).isValid() {
//                pc.session = (sender as! SPTSession)
//            }
//        }
	
    }

    @IBAction func LoginSpotify(sender: UIButton) {
        
        //let url = SPTAuth.loginURLForClientId(clientID, withRedirectURL: Callback, scopes: scope as! [AnyObject], responseType: response)
        let auth = SPTAuth.defaultInstance()
        
        
        
        auth.clientID = clientID
        auth.redirectURL = Callback
        //auth.tokenSwapURL = kTokenSwapURL
       // auth.tokenRefreshURL = kTokenRefreshURL
        auth.requestedScopes = scope as! [AnyObject]
        
        
        let url = auth.loginURL
        
        UIApplication.sharedApplication().openURL(url)

    }

}

