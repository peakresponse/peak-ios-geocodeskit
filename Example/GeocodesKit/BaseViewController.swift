//
//  BaseViewController.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/11/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit
import Foundation

@MainActor
class BaseViewController: UITableViewController, UIDocumentPickerDelegate {
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        performQuery()
    }

    func performQuery() {

    }

    func didObserveRealmChanges<T: Object>(_ changes: RealmCollectionChange<Results<T>>) {
        switch changes {
        case .initial:
            tableView.reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            tableView.beginUpdates()
            tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
            tableView.endUpdates()
        case .error(let error):
            print(error)
        }
    }

    @IBAction func importPressed() {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeItem)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func openPressed() {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeItem)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction @MainActor func exportPressed() {
        showSpinner()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let realm = try? GEORealm.open() {
                let fileManager = FileManager.default
                let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let url = documentDirectory?.appendingPathComponent("Geocodes.realm")
                if let url = url {
                    if fileManager.fileExists(atPath: url.path) {
                        try? fileManager.removeItem(at: url)
                    }
                    do {
                        try realm.writeCopy(toFile: url, encryptionKey: nil)
                        DispatchQueue.main.async { [weak self] in
                            let picker = UIDocumentPickerViewController(url: url, in: .moveToService)
                            picker.shouldShowFileExtensions = true
                            self?.present(picker, animated: true)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.hideSpinner()
            }
        }
    }

    func showSpinner() {
        for item in navigationItem.leftBarButtonItems ?? [] {
            item.isEnabled = false
        }
        for item in navigationItem.rightBarButtonItems ?? [] {
            item.isEnabled = false
        }
        var spinner: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
        } else {
            spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        }
        spinner.startAnimating()
        navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: spinner))
    }

    func hideSpinner() {
        _ = navigationItem.leftBarButtonItems?.popLast()
        for item in navigationItem.rightBarButtonItems ?? [] {
            item.isEnabled = true
        }
    }

    func importCodes(from url: URL) {

    }

    func openRealm(from url: URL) {
        showSpinner()
        GEORealm.configure(url: url, isReadOnly: true)
        performQuery()
        hideSpinner()
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let url = urls[0]
        if url.pathExtension == "realm" {
            openRealm(from: url)
        } else if url.pathExtension == "xml" {
            importCodes(from: url)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
