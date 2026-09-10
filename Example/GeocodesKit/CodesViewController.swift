//
//  CodesViewController.swift
//  GeocodesKit_Example
//
//  Created by Francis Li on 11/29/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit

class CodesViewController: UITableViewController {
    var chapter: CMChapter?
    var results: Results<CMCode>?
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
        results = realm.objects(CMCode.self)
            .filter("section.chapter=%@", chapter as Any)
            .sorted(byKeyPath: "name", ascending: true)

        if realm.configuration.readOnly {
            tableView.reloadData()
        } else {
            notificationToken = results?.observe { [weak self] (changes) in
                self?.didObserveRealmChanges(changes)
            }
        }
    }

    func didObserveRealmChanges(_ changes: RealmCollectionChange<Results<CMCode>>) {
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

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Code", for: indexPath)
        if let code = results?[indexPath.row] {
            cell.textLabel?.text = "(\(code.lft ?? 0)|\(code.rgt ?? 0)) \(code.name ?? ""): \(code.desc ?? "")"
            cell.indentationLevel = code.depth ?? 0
            cell.accessoryType = code.isLeaf ? .checkmark : .none
        }
        return cell
    }
}
