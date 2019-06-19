//
//  MainViewController.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 6/18/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import UIKit
import ITunesBrowsing

class MainViewController: UITabBarController {
    
    private var onlineItemsViewController: OnlineItemsViewController?
    private var offlineItemsViewController: OfflineItemsViewController?

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addViewControllers()
    }
    
    private func addViewControllers() {
        let frameworkBundle = Bundle(for: OnlineItemsViewController.self)
        let storyboard = UIStoryboard(name: ITBConstants.storyboardName, bundle: frameworkBundle)
        
        setUpOnlineItemsViewController(from: storyboard)
        setUpOfflineItemsViewController(from: storyboard)

        viewControllers = [onlineItemsViewController!, offlineItemsViewController!]
    }
    
    private func setUpOnlineItemsViewController(from storyboard: UIStoryboard) {
        onlineItemsViewController = (storyboard.instantiateViewController(withIdentifier: String(describing: OnlineItemsViewController.self)) as! OnlineItemsViewController)
        
        onlineItemsViewController?.dataSource = OnlineDataManager.sharedInstance
        onlineItemsViewController?.offlineItemsManager = OfflineDataManager.sharedInstance
    }

    private func setUpOfflineItemsViewController(from storyboard: UIStoryboard) {
        offlineItemsViewController = (storyboard.instantiateViewController(withIdentifier: String(describing: OfflineItemsViewController.self)) as! OfflineItemsViewController)
        
        offlineItemsViewController?.offlineItemsManager = OfflineDataManager.sharedInstance
    }
}
