//
//  CMCode.swift
//  GeocodesKit
//
//  Created by Francis Li on 11/29/21.
//

import Foundation
import RealmSwift

open class CMCode: Object {
    @Persisted(primaryKey: true) open var name: String?
    @Persisted open var desc: String?
    @Persisted open var section: CMSection?
    @Persisted open var parent: CMCode?
    @Persisted(originProperty: "parent") open var children: LinkingObjects<CMCode>
    @Persisted open var depth: Int?
    @Persisted open var lft: Int?
    @Persisted open var rgt: Int?
    open var isLeaf: Bool {
        if let lft = lft, let rgt = rgt {
            return rgt - lft == 1
        }
        return false
    }
}
