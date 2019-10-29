//
//  ActiveBuilder.swift
//  ActiveLabel
//
//  Created by Pol Quintana on 04/09/16.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation

typealias ActiveFilterPredicate = ((String) -> Bool)

struct ActiveBuilder {

    static func createElements(type: ActiveType, from text: String, range: NSRange, filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        switch type {
        case .mention, .hashtag:
            return createElementsIgnoringFirstCharacter(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .url:
            return createElements(from: text, for: type, range: range, filterPredicate: filterPredicate)
        case .custom:
            return createElements(from: text, for: type, range: range, minLength: 1, filterPredicate: filterPredicate)
        }
    }

    static func createURLElements(from text: String, range: NSRange, maximumLength: Int?) -> ([ElementTuple], String) {
        let type = ActiveType.url
        var text = text
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []

        for match in matches where match.range.length > 2 {
            let range0 = match.range(at: 0)
            let range3 = match.range(at: 3)
            let range6 = match.range(at: 6)
            let range7 = match.range(at: 7)
            let range8 = match.range(at: 8)
            let range9 = match.range(at: 9)

            let word: String
            let alter: String
            let link: String

            if range6.length > 0 && range7.length > 0 {
                word = nsstring.substring(with: range0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                alter = nsstring.substring(with: range6).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                link = nsstring.substring(with: range7).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            else if range8.length > 0 {
                word = nsstring.substring(with: range0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                link = nsstring.substring(with: range8).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                if range9.length > 0 {
                    alter = nsstring.substring(with: range9).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
                else {
                    alter = link
                }
            }
            else {
                word = nsstring.substring(with: range3).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                alter = word
                link = word
            }

            let trimmedAlter: String
            if let maxLength = maximumLength, alter.count > maxLength {
                trimmedAlter = alter.trim(to: maxLength)
            }
            else {
                trimmedAlter = alter
            }
            text = text.replacingOccurrences(of: word, with: trimmedAlter)

            let newRange = (text as NSString).range(of: trimmedAlter)
            let element = ActiveElement.url(original: word, alter: trimmedAlter, link: link)
            elements.append((newRange, element, type))
        }
        return (elements, text)
    }

    private static func createElements(from text: String,
                                            for type: ActiveType,
                                                range: NSRange,
                                                minLength: Int = 2,
                                                filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {

        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []

        for match in matches where match.range.length > minLength {
            let word = nsstring.substring(with: match.range)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }

    private static func createElementsIgnoringFirstCharacter(from text: String,
                                                                  for type: ActiveType,
                                                                      range: NSRange,
                                                                      filterPredicate: ActiveFilterPredicate?) -> [ElementTuple] {
        let matches = RegexParser.getElements(from: text, with: type.pattern, range: range)
        let nsstring = text as NSString
        var elements: [ElementTuple] = []

        for match in matches where match.range.length > 2 {
            let range = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            var word = nsstring.substring(with: range)
            if word.hasPrefix("@") {
                word.remove(at: word.startIndex)
            }
            else if word.hasPrefix("#") {
                word.remove(at: word.startIndex)
            }

            if filterPredicate?(word) ?? true {
                let element = ActiveElement.create(with: type, text: word)
                elements.append((match.range, element, type))
            }
        }
        return elements
    }
}
