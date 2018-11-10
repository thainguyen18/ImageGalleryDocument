//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Thai Nguyen on 10/29/18.
//  Copyright © 2018 Thai Nguyen. All rights reserved.
//

import UIKit

typealias ImageProperties = (url: URL, widthHeightRatio: CGFloat)

class ImageGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate
{
    // MARK: - Image Gallery Document
    
    // Computed Model
    // If someone asks for it, return current state
    // If someone sets it, update UI
    var imageGallery: ImageGallery? {
        get {
            return ImageGallery(name: document?.localizedName ?? "Untitled", images: imagesList)
        }
        
        set {
            if let images = newValue?.images {
                imagesList = images
                imageGalleryCollectionView?.reloadData()
            }
        }
    }
    
    var documentPath: URL {
        get {
            let path = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Untitled.json")
            
            if path != nil {
                return path!
            } else {
                return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Untitled.json")
            }
        }
    }
    
    var document: ImageGalleryDocument?
    
    @IBAction func close(_ sender: Any) {
        
        // Dismiss ourselves from having been presented modally
        // then close document
        // No need to save because we already save changes whenever they happen
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    private func saveChanges() {
        
        document?.imageGallery = imageGallery
        document?.updateChangeCount(.done)
        
        print("Saved!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        document?.open { success in
            if success {
                self.navigationItem.title = self.document?.localizedName ?? "Untitled"
                
                self.imageGallery = self.document?.imageGallery
            }
        }
        
        // Enable drag in iPhone as it is disabled by default
        imageGalleryCollectionView.dragInteractionEnabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        saveChanges()
        
        document?.close()
        print("Closed document")
    }
    
    
    // MARK: - Model
    var imagesList: [ImageGallery.ImageProperties] = []

    
    // MARK: - Outlets

    @IBOutlet weak var imageGalleryCollectionView: UICollectionView! {
        
        didSet {
            imageGalleryCollectionView.dataSource = self
            imageGalleryCollectionView.delegate = self
            imageGalleryCollectionView.dragDelegate = self
            imageGalleryCollectionView.dropDelegate = self
            
            imageGalleryCollectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.scaleCellSize(by:))))
        }
    }
    
    @objc private func scaleCellSize(by regconizer: UIPinchGestureRecognizer) {
        switch regconizer.state {
        case .changed, .ended:
            imageGalleryCollectionCellWidth *= regconizer.scale
            regconizer.scale = 1.0
            flowLayout?.invalidateLayout()
        default:
            break
        }
        
    }
    
    private var imageGalleryCollectionCellWidth: CGFloat = 100 // Default cell width is 100.0
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return imageGalleryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    
    // MARK: - Collection View Datasource Delegate
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageGalleryCollectionView.dequeueReusableCell(withReuseIdentifier: "ImageGalleryCollectionViewCell", for: indexPath)
        if let imageCell = cell as? ImageGalleryCollectionViewCell {
            let url = imagesList[indexPath.item].url
            imageCell.url = url
        }
        return cell
    }
    
    // MARK: - Collection View Flowlayout Delegate
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let ratio = imagesList[indexPath.item].widthHeightRatio
        
        return CGSize(width: imageGalleryCollectionCellWidth, height: imageGalleryCollectionCellWidth / ratio)
    }
    
    // MARK: - Collection View Drag Delegate
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = imageGalleryCollectionView
        return dragsItem(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragsItem(at: indexPath)
    }
    
    private func dragsItem(at indexPath: IndexPath) -> [UIDragItem] {
        if let url = (imageGalleryCollectionView.cellForItem(at: indexPath) as? ImageGalleryCollectionViewCell)?.url {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: url as NSURL))
            dragItem.localObject = url
            return [dragItem]
        } else {
            return []
        }
    }
    
    // MARK: - Collection View Drop Delegate
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if let _ = session.localDragSession { // If draging from local app
            return session.canLoadObjects(ofClass: NSURL.self)
        } else { // Or drag from other resources
            return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == imageGalleryCollectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath { // Local drop an item
                
                imageGalleryCollectionView.performBatchUpdates({
                    let removedItem = imagesList.remove(at: sourceIndexPath.item)
                    imagesList.insert(removedItem, at: destinationIndexPath.item)
                    imageGalleryCollectionView.deleteItems(at: [sourceIndexPath])
                    imageGalleryCollectionView.insertItems(at: [destinationIndexPath])
                    
                    // Update document model
                    saveChanges()
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                
            } else { // Drop from other resources
                
                let placeHolderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceHolderCell"))
                
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { [weak self] (provider, error) in
                    if let url = provider as? NSURL {
                        let session = URLSession(configuration: .default)
                        let imageURL = (url as URL).imageURL
                        let downloadTask = session.dataTask(with: imageURL) { (data, urlResponse, error) in
                            if error != nil {
                                return
                            } else {
                                if let imageData = data {
                                    if let image = UIImage(data: imageData) {
                                        let ratio = image.size.width / image.size.height
                                        
                                        DispatchQueue.main.async {
                                            placeHolderContext.commitInsertion(dataSourceUpdates: { insertIndexPath in
                                                self?.imagesList.insert(ImageGallery.ImageProperties(url: imageURL, widthHeightRatio: ratio), at: insertIndexPath.item)
                                                
                                                // Update document model
                                                self?.saveChanges()
                                                
                                                // Save to cache
                                                if let response = urlResponse {
                                                    URLCache.shared.storeCachedResponse(CachedURLResponse(response: response, data: imageData), for: URLRequest(url: imageURL))
                                                    print("Cached!")
                                                    print("Usage: \(URLCache.shared.currentDiskUsage) Bytes and capacity is \(URLCache.shared.diskCapacity) Bytes")
                                                }
                                            })
                                        }
                                    }
                                } else {
                                    placeHolderContext.deletePlaceholder()
                                }
                            }
                        }
                        downloadTask.resume()
                    } else {
                        // Delete placeholder if can't load image
                        DispatchQueue.main.async {
                            placeHolderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
        
    }
    
    // MARK: - URL Cache
    private var cache = URLCache.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 10 MB memory and disk limits
        let cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 10 * 1024 * 1024, diskPath: nil)
        
        URLCache.shared = cache
        
    }
    

    
    // MARK: - Navigation Segue

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let idVC = segue.destination as? ImageDetailViewController {
            if let imageCell = sender as? ImageGalleryCollectionViewCell {
                idVC.navigationItem.title = "Image Detail"
                idVC.image = imageCell.image
            }
        }
        
    }
    

}
