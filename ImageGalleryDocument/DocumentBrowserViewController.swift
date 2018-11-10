//
//  DocumentBrowserViewController.swift
//  ImageGalleryDocument
//
//  Created by Thai Nguyen on 11/8/18.
//  Copyright © 2018 Thai Nguyen. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        // Update the style of the UIDocumentBrowserViewController
        // browserUserInterfaceStyle = .dark
        // view.tintColor = .white
        
        // Specify the allowed content types of your application via the Info.plist.
        
        // Do any additional setup after loading the view, typically from a nib.
        
        // Only allow creation of new document on iPad
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Create blank document in Application Support directory
            // This template will be copied to Documents directory for new docs
            template = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Untitled.imagegallery")
            
            if template != nil {
                // Allow document creation and then create a new empty one
                allowsDocumentCreation = FileManager.default.createFile(atPath: template!.path, contents: Data())
            }
        }
    }
    
    private var template: URL? // Blank template for new documents
    
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        // Call the pass-in handler with our template
        // We copy it to make new documents
        
        importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    func presentDocument(at documentURL: URL) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        // Get the MVC we are going to use with our Image Gallery
        // Note that we first instantiate the navigation controller
        let documentVC = storyBoard.instantiateViewController(withIdentifier: "DocumentMVC")
        
        // Now use the "contents" method in Utilies to get to the Image Gallery VC
        if let imageGalleryViewController = documentVC.contents as? ImageGalleryViewController {
            // Set image gallery of VC
            imageGalleryViewController.document = ImageGalleryDocument(fileURL: documentURL)
        }
        
        
        // Present the MVC to show document modally
        // This will take over the entire screen until it dismisses itself
        present(documentVC, animated: true, completion: nil)
    }
}

