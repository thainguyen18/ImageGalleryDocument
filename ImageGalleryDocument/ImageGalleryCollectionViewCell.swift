//
//  ImageGalleryCollectionViewCell.swift
//  Image Gallery
//
//  Created by Thai Nguyen on 10/29/18.
//  Copyright © 2018 Thai Nguyen. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewCell: UICollectionViewCell
{
    
    @IBOutlet weak var spiner: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!
    
    var url = URL(string: "") {
        didSet {
            // Check if cache for this url exists and load
            if let cachedResponse = cache.cachedResponse(for: URLRequest(url: self.url!)), let image = UIImage(data:cachedResponse.data) {
                
                self.spiner.stopAnimating()
                self.imageView.image = image
                
                // Prepare for detail
                self.image = image
            } else {
                
                // Go to network and obtain the image data
                DispatchQueue.global().async {
                    let imageData = try? Data(contentsOf: self.url!)
                    
                    
                    DispatchQueue.main.async {
                        self.spiner.stopAnimating()
                        
                        self.imageView?.image = UIImage(data: imageData!)
                        
                        // Update image data in prepare for image detail segue
                        self.image = UIImage(data: imageData!) ?? UIImage()
                    }
                }
            }
        }
    }
    
    var image = UIImage()
    
    private var cache = URLCache.shared
}

