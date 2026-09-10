//
//  ICD10CMParser.swift
//  GeocodesKit_Example
//
//  Created by Francis Li on 11/29/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import GeocodesKit
import RealmSwift

protocol ICD10CMParserDelegate: NSObject {
    func icd10CMParserDidFinish(_ parser: ICD10CMParser)
}

class ICD10CMParser: NSObject, @preconcurrency XMLParserDelegate {
    weak var delegate: ICD10CMParserDelegate?

    var parser: XMLParser?
    var realm: Realm?

    var chapter: CMChapter?
    var section: CMSection?
    var codes: [CMCode] = []
    var text: String = ""
    var index: Int = 1

    init(url: URL) {
        super.init()
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self
        self.parser = parser
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.parser?.parse()
        }
    }

    // MARK: - XMLParserDelegate

    @MainActor func parserDidStartDocument(_ parser: XMLParser) {
        realm = CMRealm.open()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "chapter":
            chapter = CMChapter()
        case "section":
            section = CMSection()
            section?.id = attributeDict["id"]
            section?.chapter = chapter
        case "diag":
            let code = CMCode()
            code.section = section
            code.parent = codes.last
            code.depth = codes.count
            code.lft = index
            index += 1
            codes.append(code)
        default:
            text = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text = "\(text)\(string)"
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "chapter":
            chapter = nil
        case "section":
            section = nil
        case "diag":
            if let code = codes.popLast() {
                try! realm?.write {
                    code.rgt = index
                    index += 1
                    realm?.add(code, update: .modified)
                }
            }
        case "name":
            if let code = codes.last {
                code.name = text
            } else if let chapter = chapter {
                chapter.name = text
                chapter.position = Int(text)
            }
        case "desc":
            if let code = codes.last {
                code.desc = text
            } else if let section = section {
                section.desc = text
            } else if let chapter = chapter {
                chapter.desc = text
            }
        default:
            break
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        realm = nil
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.icd10CMParserDidFinish(self)
        }
    }
}
