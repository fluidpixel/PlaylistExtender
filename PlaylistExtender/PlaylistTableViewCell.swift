//
//  PlaylistTableViewCell.swift
//  PlaylistExtender
//
//  Created by Stuart Varrall on 08/07/2015.
//  Copyright (c) 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PlaylistTableViewCell: UITableViewCell {

    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var trackCount: UILabel!
    @IBOutlet weak var detailButton: UIButton!
    
    @IBOutlet weak var backgroundImage: UIImageView! {
        didSet {

            let blur = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let effectView = UIVisualEffectView(effect: blur)
            effectView.frame = backgroundImage.frame
//            effectView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleTopMargin, UIViewAutoresizing.FlexibleBottomMargin]
            effectView.translatesAutoresizingMaskIntoConstraints = false
            backgroundImage.addSubview(effectView)

            let views = ["newView": effectView]
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[newView]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views)
            backgroundImage.addConstraints(horizontalConstraints)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[newView]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
            backgroundImage.addConstraints(verticalConstraints)
            
//            let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blur)
//            let vibrancyEffectView = UIVisualEffectView(effect: vibrancyEffect)
//            vibrancyEffectView.frame = backgroundImage.frame
//            vibrancyEffectView.contentView.addSubview(albumName)
////            vibrancyEffectView.contentView.addSubview(trackCount)
//            vibrancyEffectView.contentView.addSubview(detailButton)
//            
//            effectView.contentView.addSubview(vibrancyEffectView)
        }
    }
    
    private func getImageFromURL(url: NSURL, completion: ((data: NSData?) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data: NSData?, response : NSURLResponse?, error : NSError?) -> Void in
            if error != nil {
                print(error!.localizedDescription)
            }else {
                completion(data: data)
            }
        }).resume()
    }
    
    func applyImage(url : NSURL) {
        getImageFromURL(url, completion: { data in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.backgroundImage.contentMode = UIViewContentMode.ScaleAspectFill
                
//                if let filter = CIFilter(name: "CIPhotoEffectNoir") {
//                    let ciContext = CIContext(options: nil)
//                    let startImage = CIImage(image: UIImage(data: data!)!)
//                    filter.setValue(startImage, forKey: kCIInputImageKey)
//                    let filteredImageData = filter.valueForKey(kCIOutputImageKey) as! CIImage
//                    let filteredImageRef = ciContext.createCGImage(filteredImageData, fromRect: filteredImageData.extent)
//                    self.backgroundImage.image = UIImage(CGImage: filteredImageRef);
//                } else {
                    self.backgroundImage.image = UIImage(data: data!)
//                }
            })
        })
    }
    
}
