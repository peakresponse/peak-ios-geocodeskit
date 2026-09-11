//
//  StatesViewController.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/11/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit

class StatesViewController: BaseViewController {
    var results: Results<GEOState>?

    override func performQuery() {
        notificationToken?.invalidate()
        notificationToken = nil
        if let realm = try? GEORealm.open() {
            results = realm.objects(GEOState.self).sorted(byKeyPath: "id", ascending: true)
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
        let fileURL = Bundle.main.url(forResource: "states", withExtension: "txt")!
        importCodes(from: fileURL)
    }

    override func importCodes(from url: URL) {
        // Read file contents, parse lines, and upsert GEOState records
        Task.detached {
            do {
                let data = try Data(contentsOf: url)
                guard let content = String(data: data, encoding: .utf8) else {
                    print("States import: unable to decode file as UTF-8")
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

                        let id = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let abbr = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let name = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let borderStates = String(parts[4]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if id.isEmpty { continue }

                        // Upsert GEOState by primary key `id`
                        let state: GEOState
                        if let existing = realm.object(ofType: GEOState.self, forPrimaryKey: id) {
                            state = existing
                        } else {
                            state = GEOState()
                            state.id = id
                            realm.add(state, update: .modified)
                        }
                        state.name = name
                        state.abbr = abbr
                        state.borderStates.append(objectsIn: borderStates.split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) }))
                    }
                }
            } catch {
                print("States import failed: \(error)")
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "State", for: indexPath)
        if let record = results?[indexPath.row] {
            cell.textLabel?.text = "\(record.id ?? ""): \(record.name ?? "") (\(record.abbr ?? "")) - borders: \(record.borderStates.joined(separator: ", "))"
        }
        return cell
    }
}

