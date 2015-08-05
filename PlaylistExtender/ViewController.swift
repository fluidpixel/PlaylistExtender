//
//  ViewController.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 28/05/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SPTAuthViewDelegate{
    
    let response: String = "code"
    
    var session : SPTSession!
    var authViewController: SPTAuthViewController = SPTAuthViewController.authenticationViewController()
    
    @IBOutlet weak var loginButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.alpha = 0.5
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loginReceived", name: "LoginSuccessful", object: nil)
    }
    

    override func viewDidAppear(animated: Bool) {
        loginReceived()
    }
    
    func loginReceived () {
        
        let auth = SPTAuth.defaultInstance()
        
        if let session = auth.session {
            if !session.isValid() {
                SPTAuth.defaultInstance().renewSession(session, callback: { (error: NSError!, session: SPTSession!) -> Void in
                    auth.session = session
                    if error != nil {
                        print("error refreshing session: \(error)")
                        self.loginButton.alpha = 1.0
                    }
                })
            } else {
                print("session is valid")
                
                auth.session = session
                self.performSegueWithIdentifier("LoginReceived", sender: session)
            }
        } else {
            self.loginButton.alpha = 0.5
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
	
    }

    @IBAction func LoginSpotify(sender: UIButton) {
        
        authViewController.delegate = self
        authViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        authViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        self .presentViewController(authViewController, animated: true, completion: nil)
        
    }

    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        print("login failed: \(error)")
    }
    
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        print("login success")
        SPTAuth.defaultInstance().session = session
        self.performSegueWithIdentifier("LoginReceived", sender: session)
    }
    
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        print("login cancelled")
    }
}

