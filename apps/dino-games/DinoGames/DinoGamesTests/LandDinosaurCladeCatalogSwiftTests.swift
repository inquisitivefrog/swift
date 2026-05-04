//
//  LandDinosaurCladeCatalogSwiftTests.swift
//  DinoGamesTests
//
//  Swift Testing (`import Testing`).

import Testing
@testable import DinoGames

@Suite("Land dinosaur clade catalog")
struct LandDinosaurCladeCatalogSwiftTests {

    @Test("All land pool ids have a clade entry")
    func landPoolHasCladeForEachId() {
        for dino in LandDinosaurData.allDinosaurs {
            #expect(LandDinosaurCladeCatalog.cladeByCreatureId[dino.id] != nil)
        }
    }

    @Test("Helper matches dictionary for every pooled id")
    func cladeHelperMatchesMap() {
        for id in LandDinosaurData.allDinosaurs.map(\.id) {
            let mapped = LandDinosaurCladeCatalog.cladeByCreatureId[id]
            #expect(mapped != nil)
            #expect(LandDinosaurCladeCatalog.clade(forCreatureId: id) == mapped)
        }
    }

    @Test("Nine morphological buckets")
    func nineClades() {
        #expect(DinoClade.allCases.count == 9)
    }
}
