//
//  OnlineItemsViewController.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/2/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import UIKit
import AVFoundation

class OnlineItemsViewController: UIViewController {
    
    // MARK: - Constants
    
    private let lastOpenedItemsTypeInModeKeyName = "LastOpenedItemsTypeInMode"
    private let viewControllerForMode = "Online"
    
    private let lastSearchStringKeyName = "LastSearchString"
    
    private let cellReuseIdentifier = "cellReuseId"
    
    // MARK: - Outlets
    
    @IBOutlet private weak var typeSegmentedControl: UISegmentedControl!
    
    @IBOutlet private weak var searchBar: UISearchBar!
    
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.dataSource = self
            tableView.delegate = self
        }
    }
    
    @IBOutlet private weak var noResultsStackView: UIStackView!
    
    @IBOutlet private weak var noResultsLabel: UILabel! {
        didSet {
            noResultsLabel.text = "No Results"
        }
    }
    
    @IBOutlet private weak var forSearchStringLabel: UILabel!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private variables
    
    private var currentItemType: ItemType? {
        didSet {
            UserDefaults.standard.setValue(currentItemType?.rawValue, forKey: lastOpenedItemsTypeInModeKeyName + viewControllerForMode)
        }
    }
    
    private var currentSearchString: String? {
        didSet {
            if currentSearchString == "" {
                currentSearchString = nil
            }

            UserDefaults.standard.setValue(searchBar.text, forKey: lastSearchStringKeyName)
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpCurrentItemType()
        setUpTypeSegmentedControl()
        setUpSearch()
        
        let cellNib = UINib(nibName: String(describing: ItemTableViewCell.self), bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: cellReuseIdentifier)

        refreshItems()
    }
    
    // MARK: - Actions

    @IBAction private func typeSegmentedControlValueChanged(_ sender: UISegmentedControl) {
        resignSearchBarFirstResponderIfEmpty()
        
        currentItemType = ItemType.allCases[sender.selectedSegmentIndex]
        refreshItems()
    }
    
    @IBAction private func outsideTapped() {
        resignSearchBarFirstResponderIfEmpty()
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
    
    private func setUpSearch() {
        if let lastSearchString = UserDefaults.standard.value(forKey: lastSearchStringKeyName) as? String {
            currentSearchString = lastSearchString
            searchBar.text = lastSearchString
        }
    }
    
    private func refreshItems() {
        guard let itemType = currentItemType else {
            fatalError("currentItemType is nil in setUpTypeSegmentedControl() !")
        }
        
        noResultsStackView.isHidden = true

        activityIndicator.startAnimating()
        
        let searchString = currentSearchString ?? itemType.defaultSearchString()
        
        OnlineDataManager.sharedInstance.refreshItems(of: itemType, with: searchString) { success in
            DispatchQueue.main.async { [weak self] in
                if success {
                    self?.tableView.reloadData()
                    
                    if OnlineDataManager.sharedInstance.items.count > 0 {
                        self?.tableView.isHidden = false
                        self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                    } else {
                        self?.forSearchStringLabel.text = "for \"\(self?.currentSearchString ?? "")\""
                        self?.noResultsStackView.isHidden = false
                        self?.tableView.isHidden = true
                    }
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
    
    private func resignSearchBarFirstResponderIfEmpty() {
        if searchBar.isFirstResponder, searchBar.text?.count ?? -1 == 0 {
            searchBar.resignFirstResponder()
        }
    }
}

// MARK: - UITableViewDataSource

extension OnlineItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OnlineDataManager.sharedInstance.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        guard let cell = genericCell as? ItemTableViewCell else {
            return genericCell
        }
        
        let item = OnlineDataManager.sharedInstance.items[indexPath.row]
        
        configure(cell, for: item, at: indexPath)

        return cell
    }
    
    // MARK: Helper methods

    private func configure(_ cell: ItemTableViewCell, for item: Item, at indexPath: IndexPath) {
        cell.itemNameLabel?.text = "\(item.trackName)"
        cell.authorNameLabel?.text = "\(item.artistName)"
        
        // Here we check if this item is saved locally.
        let offlineItem = OfflineDataManager.sharedInstance.offlineItem(of: item.type, with: item.trackId)
        cell.savedLocallyImageView?.alpha = (offlineItem != nil ? 1 : 0)
        
        if let image = item.image {
            cell.itemImageView?.image = image
        } else {
            cell.itemImageView?.image = nil
            
            OnlineDataManager.sharedInstance.downloadImage(for: item) { [weak self] success in
                let noImageAvailableImage = UIImage(named: Constants.ImageNames.noImageAvailable)
                
                DispatchQueue.main.async {
                    if let cellDisplayingThisIndexPathNow = self?.tableView.cellForRow(at: indexPath) as? ItemTableViewCell {
                        cellDisplayingThisIndexPathNow.itemImageView?.image = success ? (item.image ?? noImageAvailableImage) : noImageAvailableImage
                        
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension OnlineItemsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = OnlineDataManager.sharedInstance.items[indexPath.row]
        
        if OfflineDataManager.sharedInstance.offlineItem(of: item.type, with: item.trackId) == nil {
            let saveAction = UIContextualAction(style: .normal, title: "Save") { (action, sourceView, handler) in
                OfflineDataManager.sharedInstance.saveOrUpdateItem(item)
                
                if let cell = tableView.cellForRow(at: indexPath) as? ItemTableViewCell {
                    UIView.animate(withDuration: 0.5) {
                        cell.savedLocallyImageView?.alpha = 1
                    }
                }
                
                handler(true)
            }
            
            saveAction.backgroundColor = view.tintColor
            
            return UISwipeActionsConfiguration(actions: [saveAction])
        } else {
            return UISwipeActionsConfiguration(actions: [])
            // We don't allow the user to save items which have already been saved locally.
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = OnlineDataManager.sharedInstance.items[indexPath.row]
        
        if let existingOfflineItem = OfflineDataManager.sharedInstance.offlineItem(of: item.type, with: item.trackId) {
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, sourceView, handler) in
                if let alertController = self?.createAlertControllerForDeletion(of: existingOfflineItem, at: indexPath, completionHandler: handler) {
                    self?.present(alertController, animated: true)
                }
                
                self?.playAlertSound()
            }
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
        } else {
            return UISwipeActionsConfiguration(actions: [])
            // We don't allow the user to delete items which have not been saved locally yet.
        }
    }
    
    // MARK: Helper methods
    
    private func createAlertControllerForDeletion(of existingOfflineItem: OfflineItem, at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) -> UIAlertController {
        let alertController = UIAlertController(title: "Would you like to delete this item from offline storage?",
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        // Here we set up PopoverPresentationController so our Action Sheet will be presented at the right position on iPad and pointing to Delete button pressed.
        if let popoverPresentationController = alertController.popoverPresentationController {
            setUpPopoverPresentationController(popoverPresentationController, for: alertController, indexPath: indexPath)
        }
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] action in
            OfflineDataManager.sharedInstance.deleteOfflineItem(existingOfflineItem)

            if let cell = self?.tableView.cellForRow(at: indexPath) as? ItemTableViewCell {
                UIView.animate(withDuration: 0.5) {
                    cell.savedLocallyImageView?.alpha = 0
                }
            }

            completionHandler(false)
            // Here we pass false to the completion handler because we don't want the item to be completely removed from the table view.
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            completionHandler(false)
        })
        
        return alertController
    }

    private func setUpPopoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, for alertController: UIAlertController, indexPath: IndexPath) {
        popoverPresentationController.sourceView = tableView.cellForRow(at: indexPath)
        
        // Here we calculate the best point for Action Sheet's arrow to point to.
        // The calculation is based on the following fact: width of Delete button equals the horizontal offset of the swiped table view cell from the table view itself.
        if let sourceView = popoverPresentationController.sourceView {
            popoverPresentationController.sourceRect = CGRect(x: sourceView.bounds.width - sourceView.frame.origin.x / 2, y: 0, width: 0, height: sourceView.bounds.height)
        }
        
        popoverPresentationController.permittedArrowDirections = [.up, .down]
    }
    
    private func playAlertSound() {
        if let url = Bundle.main.url(forResource: "alert", withExtension: "mp3") {
            if let _ = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback), let _ = try? AVAudioSession.sharedInstance().setActive(true) {
                audioPlayer = try? AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                audioPlayer?.play()
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension OnlineItemsViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resignSearchBarFirstResponderIfEmpty()
    }
}

// MARK: - UISearchBarDelegate

extension OnlineItemsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if let searchBarText = searchBar.text, currentSearchString != searchBarText {
            currentSearchString = searchBarText
            refreshItems()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        searchBar.text = ""
        currentSearchString = nil
        refreshItems()
    }
}
