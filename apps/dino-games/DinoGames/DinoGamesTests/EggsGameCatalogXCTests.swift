//
//  EggsGameCatalogXCTests.swift
//  DinoGamesTests
//

import UIKit
import XCTest
@testable import DinoGames

final class EggsGameCatalogXCTests: XCTestCase {

    func testEggsGamesShowIntroCreatureNamesUnderPortraits() {
        XCTAssertTrue(DinoEggMorphology.settings.showsCreatureNameDuringIntro)
        XCTAssertTrue(PteroEggMorphology.settings.showsCreatureNameDuringIntro)
        XCTAssertTrue(MarineEggMorphology.settings.showsCreatureNameDuringIntro)
    }

    func testEggsIntroCreatureNamesFitCompactPortraitCaption() {
        let names = Self.allIntroCreatureNames()
        XCTAssertFalse(names.isEmpty, "Expected at least one Eggs intro creature name")

        let font = UIFont.systemFont(ofSize: EggsGameIntroLabelLayout.phoneNameFont, weight: .medium)
        // Card labels may use up to ~1.45× portrait width on iPad-scaled cards.
        let maxScaledWidth = EggsGameIntroLabelLayout.compactPortraitWidth * 1.45 + 0.5
        let minScale = EggsGameIntroLabelLayout.minimumScaleFactor

        var offenders: [String] = []
        for name in names.sorted() {
            let width = (name as NSString).size(withAttributes: [.font: font]).width
            if width * minScale > maxScaledWidth {
                offenders.append("\(name) (\(Int(width))pt at \(Int(EggsGameIntroLabelLayout.phoneNameFont))pt)")
            }
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "Intro caption names must shrink to fit \(Int(EggsGameIntroLabelLayout.compactPortraitWidth * 1.45))pt: \(offenders.joined(separator: ", "))"
        )
    }

    private static func allIntroCreatureNames() -> Set<String> {
        var names = Set<String>()
        names.formUnion(introNames(from: DinoEggsGameConfigs.dinoEggs))
        names.formUnion(introNames(from: PteroEggsGameConfigs.pteroEggs))
        if let marine = MarineEggsGameConfigs.makeMarineEggs() {
            names.formUnion(introNames(from: marine))
        }
        for creature in SeaMarineReptileData.allMarineReptiles {
            guard let slug = MarineEggMorphology.marineEggsSlug(for: creature),
                  MarineEggMorphology.roundAssetsExist(forSlug: slug) else { continue }
            names.insert(creature.name)
        }
        return names
    }

    private static func introNames(from config: EggsGameConfig) -> [String] {
        config.rounds.flatMap { round in
            ([round.correctCreature] + round.distractors).map(\.name)
        }
    }
}
