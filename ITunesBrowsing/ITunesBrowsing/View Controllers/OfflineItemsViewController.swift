//
//  OfflineItemsViewController.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 6/3/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import UIKit

class OfflineItemsViewController: UIViewController {

    // MARK: - Constants
    
    private let lastOpenedItemsTypeInModeKeyName = "LastOpenedItemsTypeInMode"
    private let viewControllerForMode = "Offline"
    
    private let cellReuseIdentifier = "cellReuseId"
    
    // MARK: - Outlets
    
    @IBOutlet public weak var offlineItemsManager: OfflineItemsManager?

    @IBOutlet private weak var typeSegmentedControl: UISegmentedControl!
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet private weak var nothingIsAvailableLocallyStackView: UIStackView!
    @IBOutlet private weak var nothingIsAvailableLocallyLabel: UILabel!
    
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
        
        let cellNib = UINib(nibName: String(describing: ItemTableViewCell.self), bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        
        guard let offlineItemsManager = offlineItemsManager else { return }

        offlineItemsManager.loadItems(ofType: itemType.rawValue)
        
        tableView.reloadData()
        
        if offlineItemsManager.items.count > 0 {
            tableView.isHidden = false
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            
            nothingIsAvailableLocallyStackView.isHidden = true
        } else {
            nothingIsAvailableLocallyLabel.text = "No \(itemType.rawValue.capitalized) is available locally"
            nothingIsAvailableLocallyStackView.isHidden = false
            
            tableView.isHidden = true
        }
    }
}

// MARK: - UITableViewDataSource

extension OfflineItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offlineItemsManager?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        guard let cell = genericCell as? ItemTableViewCell else {
            return genericCell
        }
        
        if let item = offlineItemsManager? .items[indexPath.row] {
            configure(cell, for: item, at: indexPath)
        }
        
        return cell
    }
    
    // MARK: Helper method
    
    private func configure(_ cell: ItemTableViewCell, for item: Item, at indexPath: IndexPath) {
        cell.itemNameLabel?.text = "\(item.trackName)"
        cell.authorNameLabel?.text = "\(item.artistName)"
        
        // We always set alpha to 1, because all offline items are saved locally.
        cell.savedLocallyImageView?.alpha = 1
        
        let noImageAvailableImage = UIImage(named: Constants.ImageNames.noImageAvailable)
        cell.itemImageView?.image = item.image ?? noImageAvailableImage
    }
}

// MARK: - UITableViewDelegate

extension OfflineItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
