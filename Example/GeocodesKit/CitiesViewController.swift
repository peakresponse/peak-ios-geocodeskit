//
//  CitiesViewController.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/11/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import GeocodesKit
import RealmSwift
import UIKit

class CitiesViewController: BaseViewController {
    var results: Results<GEOCity>?

    override func performQuery() {
        notificationToken?.invalidate()
        notificationToken = nil
        if let realm = try? GEORealm.open() {
            results = realm.objects(GEOCity.self).sorted(by: \.id)
            if realm.configuration.readOnly {
                tableView.reloadData()
            } else {
                notificationToken = results?.observe { [weak self] (changes) in
                    self?.didObserveRealmChanges(changes)
                }
            }
        }
    }

    override func importCodes(from url: URL) {
        // FedCodes_National.txt file should be downloaded from: https://prd-tnm.s3.amazonaws.com/StagedProducts/GeographicNames/FederalCodes/FedCodes_National_Text.zip
        showSpinner()
        Task.detached {
            do {
                let data = try Data(contentsOf: url)
                guard let content = String(data: data, encoding: .utf8) else {
                    print("Cities import: unable to decode file as UTF-8")
                    return
                }
                // Split into non-empty lines
                let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

                // Open realm for writing
                let realm = try await GEORealm.openAsync()

                try realm.write {
                    print("Beginning import...")
                    var count = 0
                    var skip = true
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
                        let name = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let featureClass = String(parts[2]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if featureClass != "Civil" && featureClass != "Populated Place" && featureClass != "Military" {
                            continue
                        }
                        let censusClassCode = String(parts[4]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if censusClassCode.starts(with: "H") || censusClassCode.starts(with: "P") || censusClassCode.starts(with: "X") || censusClassCode.starts(with: "Z") {
                            continue
                        }
                        let stateId = Int(String(parts[8]).trimmingCharacters(in: .whitespacesAndNewlines))
                        let countySequence = Int(String(parts[9]).trimmingCharacters(in: .whitespacesAndNewlines))
                        if countySequence != 1 {
                            continue
                        }
                        let countyId = Int(String(parts[11]).trimmingCharacters(in: .whitespacesAndNewlines))
                        let latitude = Double(String(parts[19]).trimmingCharacters(in: .whitespacesAndNewlines))
                        let longitude = Double(String(parts[20]).trimmingCharacters(in: .whitespacesAndNewlines))

                        let city: GEOCity
                        if let existing = realm.object(ofType: GEOCity.self, forPrimaryKey: id) {
                            city = existing
                        } else {
                            city = GEOCity()
                            city.id = id
                            realm.add(city, update: .modified)
                        }
                        city.name = name
                        city.featureClass = featureClass
                        city.censusClassCode = censusClassCode
                        if let stateId {
                            city.stateId = String(format: "%02d", stateId)
                        }
                        if let countyId {
                            city.countyId = String(format: "%03d", countyId)
                        }
                        city.latitude = latitude
                        city.longitude = longitude

                        count += 1
                    }
                    print("Imported \(count) cities...")
                }
            } catch {
                print("Cities import failed: \(error)")
            }
            await MainActor.run { [weak self] in
                self?.hideSpinner()
            }
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "City", for: indexPath)
        if let record = results?[indexPath.row] {
            cell.textLabel?.text = "\(record.id ?? ""): \(record.name ?? "") (\(record.featureClass ?? ""), \(record.censusClassCode ?? "")), \(record.stateId ?? "") - \(record.countyId ?? ""), (\(record.latitude ?? 0.0), \(record.longitude ?? 0.0))"
        }
        return cell
    }
}
