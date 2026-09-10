//
//  CMRealm.swift
//  GeocodesKit
//
//  Created by Francis Li on 11/29/21.
//

import Foundation
import RealmSwift

open class CMRealm {
    @MainActor public static var main: Realm!
    @MainActor public static var mainURL: URL?
    @MainActor public static var mainMemoryIdentifier: String? = "main.realm"
    @MainActor public static var isMainReadOnly = false
    
    @MainActor public static func configure(url: URL?, isReadOnly: Bool) {
        CMRealm.main = nil
        CMRealm.mainURL = url
        CMRealm.isMainReadOnly = isReadOnly
        CMRealm.mainMemoryIdentifier = url != nil ? nil : "main.realm"
    }

    @MainActor public static func open() -> Realm {
        if Thread.current.isMainThread && CMRealm.main != nil {
            if !CMRealm.main.configuration.readOnly {
                CMRealm.main.refresh()
            }
            return CMRealm.main
        }
        let config = Realm.Configuration(fileURL: mainURL,
                                         inMemoryIdentifier: CMRealm.mainMemoryIdentifier,
                                         readOnly: CMRealm.isMainReadOnly,
                                         objectTypes: [CMChapter.self, CMSection.self, CMCode.self])
        let realm = try! Realm(configuration: config)
        if Thread.current.isMainThread {
            CMRealm.main = realm
        }
        return realm
    }
}
