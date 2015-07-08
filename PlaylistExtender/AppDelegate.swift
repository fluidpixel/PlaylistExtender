//
//  AppDelegate.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 28/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

let setup = Setup()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let Callback: NSURL = NSURL(string: "playlistextenderlogin://callback")!
    let clientID: String = "89ce87c720004dcda7261f1c49c15905"
    let clientSecret: String = "5e0e325e2b1f4dc093bfc0c2fdaefc8d"
    let kTokenSwapURL = NSURL(string: "http://localhost:1234/swap")!
    let kTokenRefreshURL = NSURL(string: "http://localhost:1234/refresh")!
    let scope: [AnyObject] = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthPlaylistReadPrivateScope]
    let response: String = "code"
    let kSessionUserDefaultsKey  = "SpotifySession"
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let auth = SPTAuth.defaultInstance()
        auth.clientID = clientID
        auth.requestedScopes = scope
        auth.redirectURL = Callback
//        auth.tokenSwapURL = kTokenSwapURL
//        auth.tokenRefreshURL = kTokenRefreshURL
        auth.sessionUserDefaultsKey = kSessionUserDefaultsKey
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        
        //if (SPTAuth.defaultInstance().canHandleURL(url)) {
            SPTAuth.defaultInstance().handleAuthCallbackWithTriggeredAuthURL(url, callback: { (error: NSError!, session: SPTSession!) -> Void in
                
                if error != nil {
                    println("error" + "\(error.localizedDescription)")
                    return
                }
                
                
                
                let defaults = NSUserDefaults.standardUserDefaults()
                
                let sessionData = NSKeyedArchiver.archivedDataWithRootObject(session)
                
                defaults.setObject(sessionData, forKey: "session_enabled")
                defaults.synchronize()
                
                NSNotificationCenter.defaultCenter().postNotificationName("LoginSuccessful", object: nil)
                
            })
       // }
        
        return false
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

