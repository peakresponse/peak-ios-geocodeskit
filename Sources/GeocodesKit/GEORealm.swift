//
//  GEORealm.swift
//  GeocodesKit
//
//  Created by Francis Li on 9/10/26.
//

import Foundation
import RealmSwift

open class GEORealm {
    @MainActor public static var main: Realm!
    @MainActor public static var mainURL: URL?
    @MainActor public static var mainMemoryIdentifier: String? = "Geocodes.realm"
    @MainActor public static var isMainReadOnly = false

    @MainActor public static func configure(url: URL?, isReadOnly: Bool) {
        GEORealm.main = nil
        GEORealm.mainURL = url
        GEORealm.isMainReadOnly = isReadOnly
        GEORealm.mainMemoryIdentifier = url != nil ? nil : "Geocodes.realm"
    }

    @MainActor
    public static func open() throws -> Realm {
        if let main = GEORealm.main {
            if !main.configuration.readOnly {
                main.refresh()
            }
            return main
        }
        let config = Realm.Configuration(fileURL: mainURL,
                                         inMemoryIdentifier: GEORealm.mainMemoryIdentifier,
                                         readOnly: GEORealm.isMainReadOnly,
                                         objectTypes: [GEOCity.self, GEOCounty.self, GEOState.self])
        let realm = try Realm(configuration: config)
        GEORealm.main = realm
        return realm
    }

    public static func openAsync() async throws -> Realm {
        let mainURL = await GEORealm.mainURL
        let mainMemoryIdentifier = await GEORealm.mainMemoryIdentifier
        let isMainReadOnly = await GEORealm.isMainReadOnly
        let config = Realm.Configuration(fileURL: mainURL,
                                         inMemoryIdentifier: mainMemoryIdentifier,
                                         readOnly: isMainReadOnly,
                                         objectTypes: [GEOCity.self, GEOCounty.self, GEOState.self])
        return try Realm(configuration: config, queue: nil)
    }
}
