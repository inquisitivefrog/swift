//
//  MarineReptileLengthCatalog.swift
//  DinoGames
//
//  Approximate total length (m, snout to tail tip) for Which Marine Reptile Is Longer.
//  Hand-tuned educational values from commonly cited adult reconstruction ranges.
//

import Foundation

enum MarineReptileLengthCatalog {
    /// Full width of `measure-marine-tape-tool` (0 m → 22 m).
    static let marineLengthTapeMaxMeters: Double = 22.0

    static let marineTotalLengthMetersByImageName: [String: Double] = [
        "marine-basal-dolichosaurus": 1.2,
        "marine-basal-hupehsuchus": 1.0,
        "marine-basal-judeasaurus": 0.8,
        "marine-basal-mesoleptos": 1.5,
        "marine-basal-mesosaurus": 1.0,
        "marine-basal-tanystropheus": 6.0,
        "marine-hali-halisaurus": 3.5,
        "marine-hali-phosphosaurus": 3.0,
        "marine-hali-pluridens": 4.0,
        "marine-ichthyo-brachypterygius": 7.0,
        "marine-ichthyo-caypullisaurus": 5.0,
        "marine-ichthyo-cymbospondylus": 10.0,
        "marine-ichthyo-eurhinosaurus": 6.5,
        "marine-ichthyo-grendelius": 5.0,
        "marine-ichthyo-ichthyosaurus": 2.5,
        "marine-ichthyo-kyhytysuka": 9.0,
        "marine-ichthyo-malawania": 3.0,
        "marine-ichthyo-mixosaurus": 4.0,
        "marine-ichthyo-ophthalmosaurus": 5.5,
        "marine-ichthyo-platypterygius": 7.0,
        "marine-ichthyo-shastasaurus": 21.0,
        "marine-ichthyo-shonisaurus": 21.0,
        "marine-ichthyo-stenopterygius": 4.0,
        "marine-ichthyo-temnodontosaurus": 9.0,
        "marine-mosa-aigialosaurus": 2.0,
        "marine-mosa-clidastes": 6.0,
        "marine-mosa-dallasaurus": 3.0,
        "marine-mosa-gavialimimus": 8.0,
        "marine-mosa-globidens": 6.0,
        "marine-mosa-hainosaurus": 15.0,
        "marine-mosa-khinjaria": 8.0,
        "marine-mosa-megapterygius": 5.0,
        "marine-mosa-mosasaurus": 17.0,
        "marine-mosa-pannoniasaurus": 6.0,
        "marine-mosa-plotosaurus": 10.0,
        "marine-mosa-prognathodon": 14.0,
        "marine-mosa-thalassotitan": 12.0,
        "marine-mosa-xenodens": 4.0,
        "marine-notho-henodus": 1.0,
        "marine-notho-nothosaurus": 4.0,
        "marine-notho-placodus": 2.5,
        "marine-plesio-aphrosaurus": 5.0,
        "marine-plesio-attenborosaurus": 5.0,
        "marine-plesio-cryptoclidus": 4.0,
        "marine-plesio-dolichorhynchops": 3.5,
        "marine-plesio-elasmosaurus": 14.0,
        "marine-plesio-hydrotherosaurus": 11.0,
        "marine-plesio-mauisaurus": 12.0,
        "marine-plesio-microcleidus": 3.0,
        "marine-plesio-muraenosaurus": 6.0,
        "marine-plesio-plesiosaurus": 4.0,
        "marine-plesio-polycotylus": 5.0,
        "marine-plesio-styxosaurus": 12.0,
        "marine-plesio-thalassomedon": 11.0,
        "marine-plesio-woolungasaurus": 5.0,
        "marine-plio-brachauchenius": 10.0,
        "marine-plio-hauffiosaurus": 7.0,
        "marine-plio-kronosaurus": 10.0,
        "marine-plio-liopleurodon": 6.5,
        "marine-plio-megacephalosaurus": 9.0,
        "marine-plio-peloneustes": 4.0,
        "marine-plio-pliosaurus": 10.0,
        "marine-plio-rhomaleosaurus": 7.0,
        "marine-plio-sachicasaurus": 8.0,
        "marine-plio-simolestes": 6.0,
        "marine-pliop-platecarpus": 6.0,
        "marine-pliop-plioplatecarpus": 6.0,
        "marine-pliop-yaguarasaurus": 8.0,
        "marine-teleo-enchodus": 1.5,
        "marine-teleo-gillicus": 0.6,
        "marine-teleo-xiphactinus": 6.0,
        "marine-testu-archelon": 4.5,
        "marine-testu-proganochelys": 0.6,
        "marine-testu-protostega": 3.5,
        "marine-thala-dakosaurus": 4.5,
        "marine-thala-metriorhynchus": 3.0,
        "marine-thala-steneosaurus": 4.0,
        "marine-tylo-kaikaifilu": 12.0,
        "marine-tylo-taniwhasaurus": 12.0,
        "marine-tylo-tylosaurus": 15.0,
    ]

    static func totalLengthMeters(forImageName imageName: String) -> Double? {
        marineTotalLengthMetersByImageName[imageName]
    }

    /// Catalog lengths ≤ 1.0 m (snout to tail), sorted shortest first — the tiniest marine reptiles in Which Marine Reptile Is Longer.
    static var marineImageNamesAtMostOneMeter: [String] {
        marineTotalLengthMetersByImageName
            .filter { $0.value <= 1.0 }
            .sorted { $0.value < $1.value || ($0.value == $1.value && $0.key < $1.key) }
            .map(\.key)
    }

    static func marineImageNamesAtMostOneMeter(playableIn creatures: [Dinosaur]) -> [String] {
        let playable = Set(creatures.compactMap(\.imageName))
        return marineImageNamesAtMostOneMeter.filter { playable.contains($0) }
    }

    static func totalLengthMeters(forCreatureId id: Int, in creatures: [Dinosaur]) -> Double? {
        guard let imageName = creatures.first(where: { $0.id == id })?.imageName else { return nil }
        return totalLengthMeters(forImageName: imageName)
    }

    /// Bundled wide length art: `measure-marine-{species}` for portrait `marine-{clade}-{species}`.
    static func measureMarineImageCandidate(forImageName imageName: String) -> String? {
        guard imageName.hasPrefix("marine-") else { return nil }
        let parts = imageName.split(separator: "-").map(String.init)
        guard parts.count >= 3 else { return nil }
        return "measure-marine-\(parts[parts.count - 1])"
    }

    /// Resolves bundled `measure-marine-*` when present in the asset catalog.
    static func measureMarineImageName(forImageName imageName: String) -> String? {
        guard let candidate = measureMarineImageCandidate(forImageName: imageName),
              ImageAssetCache.imageExists(named: candidate) else { return nil }
        return candidate
    }

    /// Bundled wide strips authored with the snout on the trailing (right) edge — mirror at display time so 0 m aligns with the snout.
    static func measureMarineImageMirroredForTapeAlignment(forImageName imageName: String) -> Bool {
        guard let candidate = measureMarineImageCandidate(forImageName: imageName) else { return false }
        let slug = candidate.replacingOccurrences(of: "measure-marine-", with: "")
        return measureMarineSnoutOnTrailingInAssetSlugs.contains(slug)
    }

    /// Confirmed head-right in bundled PNGs (JSON pose text may still say “left to right”).
    private static let measureMarineSnoutOnTrailingInAssetSlugs: Set<String> = [
        "elasmosaurus",
        "hainosaurus",
        "pluridens",
        "thalassomedon",
        "tylosaurus",
    ]

    /// Horizontal scale on the 0–22 m tape from catalog length only.
    static func measureMarineTapeDisplayScale(forImageName imageName: String, lengthMeters: Double) -> CGFloat {
        guard marineLengthTapeMaxMeters > 0 else { return 1.0 }
        return CGFloat(lengthMeters / marineLengthTapeMaxMeters)
    }

    // MARK: - Tape visibility zoom

    /// When the longer reptile uses less than this share of the 0–22 m tape at 1×, zoom in (~16.5 m at 22 m).
    static let marineLengthTargetLongestTapeFraction: Double = 0.75

    /// Skip zoom when the computed factor is below this — marginal zoom switches to vector labels without much gain.
    static let marineLengthMinAppliedTapeVisibilityMagnification: Double = 1.5

    /// Maximum horizontal zoom (22 m tape trailing edge may leave the screen — meter marks are leading-aligned).
    static let marineLengthMaxTapeVisibilityMagnification: Double = 8.0

    /// Zoom so the **longer** locked-in reptile fills ~75% of the visible tape column without exceeding 22 m.
    /// Uses the first pick alone until a second is chosen; never shrinks below 1×.
    static func tapeVisibilityMagnification(firstMeters: Double?, secondMeters: Double?) -> CGFloat {
        guard let first = firstMeters, first > 0 else { return 1.0 }
        let referenceMeters: Double
        if let second = secondMeters, second > 0 {
            referenceMeters = max(first, second)
        } else {
            referenceMeters = first
        }
        return tapeMagnification(forReferenceLengthMeters: referenceMeters)
    }

    private static func tapeMagnification(forReferenceLengthMeters length: Double) -> CGFloat {
        guard length > 0, marineLengthTapeMaxMeters > 0 else { return 1.0 }
        let naturalFraction = length / marineLengthTapeMaxMeters
        guard naturalFraction > 0 else { return 1.0 }
        if naturalFraction >= marineLengthTargetLongestTapeFraction { return 1.0 }
        let needed = marineLengthTargetLongestTapeFraction / naturalFraction
        let clamped = min(max(needed, 1.0), marineLengthMaxTapeVisibilityMagnification)
        if clamped < marineLengthMinAppliedTapeVisibilityMagnification { return 1.0 }
        return CGFloat(clamped)
    }

    // MARK: - Vector tape ruler (Canvas)

    /// Tick spacing for the zoomed vector tape (0.5 m when the visible window is tiny).
    static func tapeRulerTickStepMeters(visibleMeters: Double) -> Double {
        visibleMeters <= 3.5 ? 0.5 : 1.0
    }

    /// Label every N whole meters so text stays readable at the current pixels-per-meter.
    static func tapeRulerLabelIntervalMeters(visibleMeters: Double, clipWidth: CGFloat, minLabelSpacing: CGFloat = 26) -> Int {
        guard visibleMeters > 0, clipWidth > 0 else { return 1 }
        let pxPerMeter = Double(clipWidth) / visibleMeters
        guard pxPerMeter > 0 else { return 1 }
        return max(1, Int(ceil(Double(minLabelSpacing) / pxPerMeter)))
    }

    /// True when `second` is an allowed second pick after `first` is locked in.
    static func marineLengthPairIsPlayable(firstMeters: Double, secondMeters: Double) -> Bool {
        ComparisonGameLogic.marineLengthSecondPickResult(firstMeters: firstMeters, secondMeters: secondMeters) == .allowed
    }

    /// Every grid choice must have at least one other round mate that can be chosen second.
    static func marineRoundLengthsAreFullyComparable(_ lengths: [Double]) -> Bool {
        guard lengths.count >= 2 else { return false }
        for first in lengths {
            let hasPartner = lengths.contains { second in
                second != first && marineLengthPairIsPlayable(firstMeters: first, secondMeters: second)
            }
            if !hasPartner { return false }
        }
        return true
    }
}
