//
//  CountiesViewController.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/11/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit

class CountiesViewController: BaseViewController {
    var results: Results<GEOCounty>?

    override func performQuery() {
        notificationToken?.invalidate()
        notificationToken = nil
        if let realm = try? GEORealm.open() {
            results = realm.objects(GEOCounty.self).sorted(byKeyPath: "id", ascending: true)
            if realm.configuration.readOnly {
                tableView.reloadData()
            } else {
                notificationToken = results?.observe { [weak self] (changes) in
                    self?.didObserveRealmChanges(changes)
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "County", for: indexPath)
        if let record = results?[indexPath.row] {
            cell.textLabel?.text = "\(record.id ?? ""): \(record.name ?? "")"
        }
        return cell
    }
}

