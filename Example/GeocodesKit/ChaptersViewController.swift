//
//  ChaptersViewController.swift
//  GeocodesKit
//
//  Created by Francis Li on 11/29/2021.
//  Copyright (c) 2021 Francis Li. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit
import Foundation

class ChaptersViewController: UITableViewController, UIDocumentPickerDelegate, ICD10CMParserDelegate {
    var parser: ICD10CMParser?
    var results: Results<CMChapter>?
    var notificationToken: NotificationToken?

    deinit {
        notificationToken?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        performQuery()
    }

    func performQuery() {
        notificationToken?.invalidate()
        notificationToken = nil
        let realm = CMRealm.open()
        results = realm.objects(CMChapter.self).sorted(byKeyPath: "position", ascending: true)
        if realm.configuration.readOnly {
            tableView.reloadData()
        } else {
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<CMChapter>>) {
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
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeXML)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func openPressed() {
        let picker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeItem)], in: .open)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func exportPressed() {
        showSpinner()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let realm = CMRealm.open()
            let fileManager = FileManager.default
            let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = documentDirectory?.appendingPathComponent("ICD10CM.realm")
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
        showSpinner()
        parser = ICD10CMParser(url: url)
        parser?.delegate = self
        parser?.start()
    }

    func openRealm(from url: URL) {
        showSpinner()
        CMRealm.configure(url: url, isReadOnly: true)
        performQuery()
        hideSpinner()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow,
           let chapter = results?[indexPath.row],
           let vc = segue.destination as? CodesViewController {
            vc.chapter = chapter
        }
    }

    // MARK: - ICD10CMParserDelegate

    func icd10CMParserDidFinish(_ parser: ICD10CMParser) {
        hideSpinner()
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let url = urls[0]
        if url.pathExtension == "xml" {
            importCodes(from: url)
        } else if url.pathExtension == "realm" {
            openRealm(from: url)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Chapter", for: indexPath)
        if let chapter = results?[indexPath.row] {
            cell.textLabel?.text = "\(chapter.name ?? ""): \(chapter.desc ?? "")"
        }
        return cell
    }
}
