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
