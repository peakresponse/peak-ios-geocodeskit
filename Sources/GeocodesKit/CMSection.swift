//
//  CMSection.swift
//  GeocodesKit
//
//  Created by Francis Li on 11/29/21.
//

import Foundation
import RealmSwift

open class CMSection: Object {
    @Persisted(primaryKey: true) open var id: String?
    @Persisted open var desc: String?
    @Persisted open var first: String?
    @Persisted open var last: String?
    @Persisted open var chapter: CMChapter?
    @Persisted(originProperty: "section") open var codes: LinkingObjects<CMCode>
}
