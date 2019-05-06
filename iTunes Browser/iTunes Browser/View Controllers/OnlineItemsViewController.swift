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
    
    private let lastOpenedItemsTypeInModeKeyName = "LastOpenedItemsTypeInMode"
    private let viewControllerForMode = "Online"
    
    private let cellReuseIdentifier = "cellReuseId"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var typeSegmentedControl: UISegmentedControl!
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private variables
    
    private var currentItemType: ItemType? {
        didSet {
            UserDefaults.standard.setValue(currentItemType?.rawValue, forKey: lastOpenedItemsTypeInModeKeyName + viewControllerForMode)
        }
    }
    
    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpCurrentItemType()
        setUpTypeSegmentedControl()
        
        // Temporarily for test purposes.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

        refreshItems()
    }
    
    // MARK: - Actions

    @IBAction private func typeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        currentItemType = ItemType.allCases[sender.selectedSegmentIndex]
        refreshItems()
    }
    
    // MARK: - Internal
    
    private func setUpCurrentItemType() {
        if let lastItemTypeString = UserDefaults.standard.string(forKey: lastOpenedItemsTypeInModeKeyName + viewControllerForMode), let lastItemType = ItemType(rawValue: lastItemTypeString) {
            currentItemType = lastItemType
        } else {
            currentItemType = ItemType.allCases.first
        }
    }
    
    private func setUpTypeSegmentedControl() {
        typeSegmentedControl.removeAllSegments()
        
        for type in ItemType.allCases {
            typeSegmentedControl.insertSegment(withTitle: type.rawValue.capitalized, at: typeSegmentedControl.numberOfSegments, animated: false)
        }
        
        guard let itemType = currentItemType else {
            fatalError("currentItemType is nil in setUpTypeSegmentedControl() !")
        }
        
        guard let indexOfCurrentItemType = ItemType.allCases.firstIndex(of: itemType) else {
            fatalError("currentItemType not found in ItemType.allCases !")
        }
        
        typeSegmentedControl.selectedSegmentIndex = indexOfCurrentItemType
    }
    
    private func refreshItems() {
        guard let itemType = currentItemType else {
            fatalError("currentItemType is nil in setUpTypeSegmentedControl() !")
        }

        activityIndicator.startAnimating()
        
        OnlineDataManager.sharedInstance.refreshItems(ofType: itemType, withSearchString: itemType.defaultSearchString()) { success in
            DispatchQueue.main.async { [weak self] in
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
