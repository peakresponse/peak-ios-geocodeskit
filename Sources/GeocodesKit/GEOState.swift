//
//  GEOState.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/10/26.
//

import Foundation
import RealmSwift

open class GEOState: Object {
    @Persisted(primaryKey: true) open var id: String?
    @Persisted open var name: String?
    @Persisted open var abbr: String?
    @Persisted open var borderStates: List<String>
}
