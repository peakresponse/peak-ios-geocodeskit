//
//  GEOCounty.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/10/26.
//

import Foundation
import RealmSwift

open class GEOCounty: Object {
    @Persisted(primaryKey: true) open var id: String?
    @Persisted open var name: String?
    @Persisted open var state: GEOState?
    @Persisted open var fipsClass: String?
    @Persisted open var status: String?
}
