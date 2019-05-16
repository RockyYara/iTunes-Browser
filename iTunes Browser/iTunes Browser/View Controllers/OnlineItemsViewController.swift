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
    
    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpCurrentItemType()
        setUpTypeSegmentedControl()
        setUpSearch()
        
        // Temporarily for test purposes.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)

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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let saveAction = UIContextualAction(style: .normal, title: "Save") { (action, sourceView, handler) in
            let item = OnlineDataManager.sharedInstance.items[indexPath.row]
            OfflineDataManager.sharedInstance.saveOrUpdateItem(item)
            
            handler(true)
        }

        saveAction.backgroundColor = view.tintColor

        return UISwipeActionsConfiguration(actions: [saveAction])
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
