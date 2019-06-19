//
//  OnlineDataManager.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import ITunesBrowsing

class OnlineDataManager {
    
    static let sharedInstance = OnlineDataManager()
    
    private let apiHelper = APIHelper()
    private let modelParser = ModelParser()
    
    private(set) var items = [Item]()

    func refreshItems(of type: ItemType, with searchString: String, completionHandler: @escaping (Bool) -> Void) {
        apiHelper.searchItems(of: type.rawValue, with: searchString) { [weak self] resultDict in
            guard let dict = resultDict else {
                completionHandler(false)
                return
            }
            
            guard let resultsArray = dict["results"] as? [Any] else {
                completionHandler(false)
                return
            }
            
            if let strongSelf = self {
                strongSelf.items = strongSelf.modelParser.parseArrayOfItems(of: type, from: resultsArray)
                // Here we supply ModelParser with the information about type of items because we definitely know the type of items we are currently requesting.
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
    
    func downloadImage(for item: Item, completionHandler: @escaping (Bool) -> Void) {
        switch item.imageDownloadStatus {
        case .notStarted, .failed:
            guard let url = item.artworkUrl60 else {
                // If we don't have image url it's not possible to download the image for given item.
                item.imageDownloadStatus = .notPossible
                completionHandler(false)
                return
            }
            
            item.imageDownloadStatus = .inProgress
            
            self.apiHelper.externalResourceGetData(with: url) { resultData in
                guard let data = resultData else {
                    item.imageDownloadStatus = .failed
                    completionHandler(false)
                    return
                }
                
                if let image = UIImage(data: data) {
                    item.image = image
                    item.imageDownloadStatus = .complete
                    // Order of these 2 lines is very important for thread safety, because they are going to be executed on background thread,
                    // and at the same time check if item.image is set can be run on the main thread (in method
                    // configure(_ cell: ItemTableViewCell, for item: Item, at indexPath: IndexPath) of OnlineItemsViewController class).
                    
                    completionHandler(true)
                } else {
                    item.imageDownloadStatus = .failed
                    completionHandler(false)
                }
            }
        case .notPossible:
            completionHandler(false)
        case .inProgress:
            // If download is already in progress, we shouldn't run completion handler at all,
            // because download status "in progress" means that completion closure for given item already exists
            // and will be run after download completes or fails.
            break
        case .complete:
            // In general we shouldn't get in this case, because each class which uses item and needs its image should check if item.image is already set,
            // and only try to initiate download if it isn't.
            // But if a class doesn't do this check on its own, we should execute completion closure.
            completionHandler(true)
        }
    }
}
