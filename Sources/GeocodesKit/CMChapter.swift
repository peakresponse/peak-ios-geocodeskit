//
//  CMChapter.swift
//  GeocodesKit
//
//  Created by Francis Li on 11/29/21.
//

import Foundation
import RealmSwift

open class CMChapter: Object {
    @Persisted(primaryKey: true) open var name: String?
    @Persisted open var position: Int?
    @Persisted open var desc: String?
    @Persisted(originProperty: "chapter") open var sections: LinkingObjects<CMSection>
}
