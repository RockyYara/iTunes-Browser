//
//  OnlineItemsViewController.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/2/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import UIKit

class OnlineItemsViewController: UIViewController {
    
    // MARK: - Constants
    
    private let cellReuseIdentifier = "cellReuseId"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Temporarily for test purposes.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Temporarily for test purposes.
        let deadlineTime = DispatchTime.now() + .seconds(2)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) { [weak self] in
            self?.activityIndicator.startAnimating()
            
            OnlineDataManager.sharedInstance.refreshMusicItems(withSearchString: "It's my life") { success in
                DispatchQueue.main.async {
                    if success {
                        self?.tableView.reloadData()
                    } else {
                        let alertController = UIAlertController(title: "Error", message: "There was an error while updating items.", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .default)
                        alertController.addAction(alertAction)
                        
                        self?.present(alertController, animated: true)
                    }
                    
                    self?.activityIndicator.stopAnimating()
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension OnlineItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OnlineDataManager.sharedInstance.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        let item = OnlineDataManager.sharedInstance.items[indexPath.row]
        
        // Temporarily for test purposes.
        cell.textLabel?.text = "\(item.trackName)"
//        cell.detailTextLabel?.text = "\(item.artistName)"
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension OnlineItemsViewController: UITableViewDelegate {
    
}
