//
//  GEOCity.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/10/26.
//

import Foundation
import RealmSwift

open class GEOCity: Object {
    @Persisted(primaryKey: true) open var id: String?
    @Persisted open var name: String?
    open var shortName: String? {
        if let name {
            if name.starts(with: "City of the ") {
                return String(name[name.index(name.startIndex, offsetBy: 12)...])
            }
            if name.starts(with: "City of ") || name.starts(with: "Town of ") {
                return String(name[name.index(name.startIndex, offsetBy: 8)...])
            }
            if name.starts(with: "Borough of ") || name.starts(with: "Village of ") {
                return String(name[name.index(name.startIndex, offsetBy: 11)...])
            }
            if name.starts(with: "Municipality of ") {
                return String(name[name.index(name.startIndex, offsetBy: 16)...])
            }
            if name.starts(with: "Metro Township of ") {
                return String(name[name.index(name.startIndex, offsetBy: 18)...])
            }
            if name.starts(with: "City and County of ") {
                return String(name[name.index(name.startIndex, offsetBy: 19)...])
            }
            if name.starts(with: "City and Borough of ") {
                return String(name[name.index(name.startIndex, offsetBy: 20)...])
            }
        }
        return name
    }
    @Persisted open var featureClass: String?
    @Persisted open var censusClassCode: String?
    @Persisted open var stateId: String?
    @Persisted open var countyId: String?
    open var countyGeoId: String? {
        if let stateId, let countyId {
            return "\(stateId)\(countyId)"
        }
        return nil
    }
    @Persisted open var latitude: Double?
    @Persisted open var longitude: Double?
}
