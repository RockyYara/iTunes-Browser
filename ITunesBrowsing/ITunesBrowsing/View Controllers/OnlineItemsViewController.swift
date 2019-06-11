//
//  OnlineItemsViewController.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/2/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import UIKit
import AVFoundation

public class OnlineItemsViewController: UIViewController {
    
    // MARK: - Constants
    
    private let lastOpenedItemsTypeInModeKeyName = "LastOpenedItemsTypeInMode"
    private let viewControllerForMode = "Online"
    
    private let lastSearchStringKeyName = "LastSearchString"
    
    private let cellReuseIdentifier = "cellReuseId"
    
    // MARK: - Outlets
    
    @IBOutlet public weak var dataSource: OnlineItemsDataSource?
    @IBOutlet public weak var offlineItemsManager: OfflineItemsManager?

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

    override public func viewDidLoad() {
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
        
        guard let dataSource = dataSource else { return }
        
        noResultsStackView.isHidden = true

        activityIndicator.startAnimating()
        
        let searchString = currentSearchString ?? itemType.defaultSearchString()
        
        dataSource.refreshItems(ofType: itemType.rawValue, withSearchString: searchString) { success in
            DispatchQueue.main.async { [weak self] in
                if success {
                    self?.tableView.reloadData()
                    
                    if dataSource.items.count > 0 {
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
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.items.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let genericCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        
        guard let cell = genericCell as? ItemTableViewCell else {
            return genericCell
        }
        
        if let item = dataSource?.items[indexPath.row] {
            configure(cell, for: item, at: indexPath)
        }

        return cell
    }
    
    // MARK: Helper methods

    private func configure(_ cell: ItemTableViewCell, for item: Item, at indexPath: IndexPath) {
        cell.itemNameLabel?.text = "\(item.trackName)"
        cell.authorNameLabel?.text = "\(item.artistName)"
        
        // Here we check if this item is saved locally.
        let offlineItem = offlineItemsManager?.item(ofType: item.type.rawValue, withTrackId: item.trackId)
        cell.savedLocallyImageView?.alpha = (offlineItem != nil ? 1 : 0)
        
        if let image = item.image {
            cell.itemImageView?.image = image
        } else {
            cell.itemImageView?.image = offlineItem?.image
            
            guard let dataSource = dataSource else { return }

            cell.activityIndicator?.startAnimating()
            
            dataSource.downloadImage(for: item) { [weak self] success in
                // We want to update the cell's image only if the cell is still displaying the item downloaded image is for.
                // This is especially important for slow networks and users making a lot of actions quickly.
                //
                // But the cell itself doesn't and shouldn't know which item it is displaying (cell is only a view).
                // Fortunately we know indexPath of the cell downloaded image is for.
                //
                // The cell at given indexPath is displaying item which can be acquired from the items array.
                // Then we compare it with the item downloaded image is for.
                
                let items = dataSource.items
                
                if items.count > indexPath.row && items[indexPath.row] === item {
                    let noImageAvailableImage = UIImage(named: Constants.ImageNames.noImageAvailable)
                    // It's perfectly legal to initialize new UIImage not on the main thread, because no actual UI is being accessed during image initialization.
                    // After that we definitely have to switch to the main thread.

                    DispatchQueue.main.async {
                        if let cellDisplayingThisIndexPathNow = self?.tableView.cellForRow(at: indexPath) as? ItemTableViewCell {
                            cellDisplayingThisIndexPathNow.activityIndicator?.stopAnimating()

                            if let imageView = cellDisplayingThisIndexPathNow.itemImageView {
                                let imageToBeSet = success ? (item.image ?? noImageAvailableImage) : noImageAvailableImage
                                let transitionKind: UIView.AnimationOptions = (imageView.image != nil) ? .transitionFlipFromRight : .transitionCrossDissolve

                                UIView.transition(with: imageView, duration: 0.5, options: transitionKind, animations: {
                                    imageView.image = imageToBeSet
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension OnlineItemsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = dataSource?.items[indexPath.row], let offlineItemsManager = offlineItemsManager else {
            return nil
            // We can't save locally anything if there are problems with getting it from data source or if we don't have offlineItemsManager set.
        }

        if offlineItemsManager.item(ofType: item.type.rawValue, withTrackId: item.trackId) == nil {
            let saveAction = UIContextualAction(style: .normal, title: "Save") { (action, sourceView, handler) in
                offlineItemsManager.saveOrUpdateItem(item)
                
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
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = dataSource?.items[indexPath.row], let _ = offlineItemsManager else {
            return UISwipeActionsConfiguration(actions: [])
            // We can't delete anything if there are problems with getting it from data source or if we don't have offlineItemsManager set.
        }
        
        if let existingOfflineItem = offlineItemsManager?.item(ofType: item.type.rawValue, withTrackId: item.trackId) {
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
    
    private func createAlertControllerForDeletion(of existingOfflineItem: Item, at indexPath: IndexPath, completionHandler: @escaping (Bool) -> Void) -> UIAlertController? {
        guard let offlineItemsManager = offlineItemsManager else {
            return nil
            // We can't return UIAlertController for deletion of an item if we don't have offlineItemsManager set.
        }
        
        let alertController = UIAlertController(title: "Would you like to delete this item from offline storage?",
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        // Here we set up PopoverPresentationController so our Action Sheet will be presented at the right position on iPad and pointing to Delete button pressed.
        if let popoverPresentationController = alertController.popoverPresentationController {
            setUpPopoverPresentationController(popoverPresentationController, for: alertController, indexPath: indexPath)
        }
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] action in
            offlineItemsManager.deleteItem(existingOfflineItem)

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
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        resignSearchBarFirstResponderIfEmpty()
    }
}

// MARK: - UISearchBarDelegate

extension OnlineItemsViewController: UISearchBarDelegate {
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if let searchBarText = searchBar.text, currentSearchString != searchBarText {
            currentSearchString = searchBarText
            refreshItems()
        }
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        searchBar.text = ""
        currentSearchString = nil
        refreshItems()
    }
}
