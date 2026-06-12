//
//  StandardVictorySequenceXCTests.swift
//  DinoGamesTests
//

import SwiftUI
import XCTest
@testable import DinoGames

@MainActor
final class StandardVictorySequenceXCTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "landDinosaurPlayedCanonicalGameIds")
        super.tearDown()
    }

    // MARK: - Asset helpers

    func testDefaultSuccessImageCandidates() {
        XCTAssertEqual(
            StandardVictorySequence.defaultSuccessImageCandidates(gameConfigId: "dino-footprints"),
            ["game-dino-footprints-success", "game-dino-footprints"]
        )
    }

    // MARK: - Layout

    func testRecapListScrollHeightCapsAtThreeVisibleRows() {
        let three = StandardVictoryLayout.recapListScrollHeight(itemCount: 3)
        let nine = StandardVictoryLayout.recapListScrollHeight(itemCount: 9)
        XCTAssertEqual(three, nine, "Recap viewport should cap at maxVisibleRecapRows")
    }

    func testRecapListScrollHeightUsesAtLeastOneRowSlot() {
        let empty = StandardVictoryLayout.recapListScrollHeight(itemCount: 0)
        let one = StandardVictoryLayout.recapListScrollHeight(itemCount: 1)
        XCTAssertEqual(empty, one)
    }

    func testRecapScrollTarget_staysAtTopForFirstThreeHighlights() {
        for index in 0..<StandardVictoryLayout.maxVisibleRecapRows {
            XCTAssertNil(
                StandardVictoryLayout.recapScrollTargetId(highlightIndex: index, itemCount: 9),
                "Highlight \(index) should not scroll (first viewport page)"
            )
        }
    }

    func testRecapScrollTarget_scrollsFromFourthHighlightForNineItemRecap() {
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 3, itemCount: 9), 3)
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 4, itemCount: 9), 4)
        XCTAssertEqual(StandardVictoryLayout.recapScrollTargetId(highlightIndex: 8, itemCount: 9), 8)
    }

    func testVictorySplitColumnDefaultsKeepOneScreenLayout() {
        let view = VictorySplitColumnView(
            listScrollHeight: StandardVictoryLayout.recapListScrollHeight(itemCount: 3),
            showSuccessPhase: true,
            endHighlightIndex: 0,
            gameTitle: "Test Game",
            scrollRows: { EmptyView() },
            successPhase: { EmptyView() }
        )
        XCTAssertFalse(view.hideGameTitleDuringSuccessPhase)
        XCTAssertFalse(view.collapseRecapListDuringSuccessPhase)
    }

    // MARK: - beginRecapWalk / advanceRecapHighlight

    func testBeginRecapWalkWithZeroItemsSkipsToSuccessStep() {
        let speech = SpeechManager()
        var step = -1
        var highlight = -1
        var spoken: [Int] = []

        StandardVictorySequence.beginRecapWalk(
            itemCount: 0,
            setEndSequenceStep: { step = $0 },
            setEndHighlightIndex: { highlight = $0 },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: {}
        )

        XCTAssertEqual(step, 2)
        XCTAssertEqual(highlight, 0)
        XCTAssertTrue(spoken.isEmpty)
    }

    func testBeginRecapWalkWalksAllItemsThenCompletes() {
        let speech = SpeechManager()
        var step = -1
        var highlight = -1
        var spoken: [Int] = []
        var completed = false

        StandardVictorySequence.beginRecapWalk(
            itemCount: 3,
            setEndSequenceStep: { step = $0 },
            setEndHighlightIndex: { highlight = $0 },
            speechManager: speech,
            speakItem: { spoken.append($0) },
            onRecapComplete: { completed = true }
        )

        XCTAssertEqual(step, 1)
        XCTAssertEqual(highlight, 0)
        XCTAssertEqual(spoken, [0])

        speech.onAudioFinished?()
        XCTAssertEqual(highlight, 1)
        XCTAssertEqual(spoken, [0, 1])

        speech.onAudioFinished?()
        XCTAssertEqual(highlight, 2)
        XCTAssertEqual(spoken, [0, 1, 2])

        speech.onAudioFinished?()
        XCTAssertTrue(completed)
    }

    // MARK: - dismissAfterVictory

    func testDismissAfterVictoryClosesSheetAndPostsLandCompletion() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .landDinosaurGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let speech = SpeechManager()
        StandardVictorySequence.dismissAfterVictory(
            configId: "weigh-dinosaur",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: speech
        )

        XCTAssertFalse(presented)
        XCTAssertNil(speech.onAudioFinished)
        XCTAssertEqual(notifiedId, "weigh-dinosaur")
    }

    func testDismissAfterVictoryNormalizesRacingConfigId() {
        var presented = true
        var notifiedId: String?
        let token = NotificationCenter.default.addObserver(
            forName: .landDinosaurGameCompleted,
            object: nil,
            queue: nil
        ) { note in
            notifiedId = note.userInfo?["gameId"] as? String
        }
        defer { NotificationCenter.default.removeObserver(token) }

        StandardVictorySequence.dismissAfterVictory(
            configId: "racing-dinosaurs-cretaceous",
            isPresented: Binding(get: { presented }, set: { presented = $0 }),
            speechManager: SpeechManager()
        )

        XCTAssertFalse(presented)
        XCTAssertEqual(notifiedId, "racing-dinosaurs")
    }

    // MARK: - playCrowdCheeringThen

    func testPlayCrowdCheeringThenInvokesCompletionAfterCrowdAudio() {
        let speech = SpeechManager()
        var completed = false
        StandardVictorySequence.playCrowdCheeringThen(speechManager: speech) {
            completed = true
        }

        if speech.urlForAudio(key: "crowd-cheering") != nil {
            XCTAssertFalse(completed, "Completion should wait for crowd audio")
            speech.onAudioFinished?()
        }
        XCTAssertTrue(completed)
    }

    // MARK: - Shipping land games use recap items

    func testShippingLandGamesProduceVictoryRecapItems() {
        let nameThat = GuessGameConfigs.nameThatDinosaur
        XCTAssertEqual(nameThat.rounds.count, 3)

        let footprints = GuessGameConfigs.dinoFootprints
        XCTAssertEqual(footprints.rounds.count, 3)

        let eggs = DinoEggsGameConfigs.dinoEggs
        XCTAssertEqual(eggs.rounds.count, 3)

        let smile = SmilingDinosGameConfigs.smilingDinos
        XCTAssertEqual(smile.rounds.count, 3)
    }
}
