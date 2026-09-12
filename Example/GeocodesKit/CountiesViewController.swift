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

    override func importPressed() {
        let fileURL = Bundle.main.url(forResource: "national_county2020", withExtension: "txt")!
        importCodes(from: fileURL)
    }

    override func importCodes(from url: URL) {
        // Read file contents, parse lines, and upsert GEOState records
        Task.detached {
            do {
                let data = try Data(contentsOf: url)
                guard let content = String(data: data, encoding: .utf8) else {
                    print("Counties import: unable to decode file as UTF-8")
                    return
                }
                // Split into non-empty lines
                let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                // Open realm for writing
                let realm = try await GEORealm.openAsync()
                var skip = true
                try realm.write {
                    for rawLine in lines {
                        if skip {
                            skip = false
                            continue
                        }
                        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        if line.isEmpty { continue }

                        // Expecting lines in the format: ID|Name
                        let parts = line.split(separator: "|", omittingEmptySubsequences: false)

                        let stateId = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let countyId = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let id = "\(stateId)\(countyId)"
                        let name = String(parts[4]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let fipsClass = String(parts[5]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let status = String(parts[6]).trimmingCharacters(in: .whitespacesAndNewlines)

                        let county: GEOCounty
                        if let existing = realm.object(ofType: GEOCounty.self, forPrimaryKey: id) {
                            county = existing
                        } else {
                            county = GEOCounty()
                            county.id = id
                            realm.add(county, update: .modified)
                        }
                        county.state = realm.object(ofType: GEOState.self, forPrimaryKey: stateId)
                        county.name = name
                        county.fipsClass = fipsClass
                        county.status = status
                    }
                }
            } catch {
                print("Counties import failed: \(error)")
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
            cell.textLabel?.text = "\(record.id ?? "") (\(record.state?.abbr ?? "")): \(record.name ?? "") (\(record.fipsClass ?? ""), \(record.status ?? ""))"
        }
        return cell
    }
}

