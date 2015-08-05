//
//  TableViewCell.swift
//  PlaylistExtender
//
//  Created by Lauren Brown on 07/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit
import Foundation

class CustomTableViewCell: UITableViewCell {

    @IBOutlet weak var Title: UILabel!
    @IBOutlet weak var AlbumImage: UIImageView!
    
    @IBOutlet weak var DetailLabel: UILabel!
    
    private func getImageFromURL(url: String, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: url)!, completionHandler: { (data: NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            }else {
                completion(data: data)
            }
        }).resume()
    }
    
    func applyImage(url : String) {
        getImageFromURL(url, completion: { data in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.AlbumImage.contentMode = UIViewContentMode.ScaleAspectFit
                self.AlbumImage.image = UIImage(data: data!)
                
            })
        })
    }

}
