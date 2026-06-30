//
//  LandDinosaurRacingCatalog.swift
//  DinoGames
//
//  Curated dinosaur racer pool for Racing Dinosaurs (L2): Mesozoic period, speeds, and bundled `dino-racer-*` art.
//

import Foundation

enum LandDinosaurRacingCatalog {
    enum Period {
        case jurassic
        case cretaceous
    }

    enum MesozoicSpan {
        case jurassic
        case cretaceous
        case both
    }

    struct Entry {
        let slug: String
        let displayName: String
        let icon: String
        let speed: Double
        /// Folder/clade slug for `dino-racer-{clade}-{species}` assets (must match imageset naming).
        let racerAssetClade: String
        let mesozoicPeriod: Period
    }

    struct PoolEntry {
        let slug: String
        let displayName: String
        let icon: String
        let speed: Double
        let racerAssetClade: String
        let racingAssetBase: String
    }

    /// Metadata for bundled `dino-racer-{slug}-*` packs; runtime pool is filtered by `hasCompleteDinosaurRacingAssetPack`.
    static let allEntries: [Entry] = [
        Entry(slug: "allosaurus", displayName: "Allosaurus", icon: "🦖", speed: 25, racerAssetClade: "theropod", mesozoicPeriod: .jurassic),
        Entry(slug: "stegosaurus", displayName: "Stegosaurus", icon: "🦎", speed: 12.5, racerAssetClade: "stegosaur", mesozoicPeriod: .jurassic),
        Entry(slug: "apatosaurus", displayName: "Apatosaurus", icon: "🦕", speed: 13.5, racerAssetClade: "sauropod", mesozoicPeriod: .jurassic),
        Entry(slug: "diplodocus", displayName: "Diplodocus", icon: "🦕", speed: 12, racerAssetClade: "sauropod", mesozoicPeriod: .jurassic),
        Entry(slug: "compsognathus", displayName: "Compsognathus", icon: "🦖", speed: 40, racerAssetClade: "theropod", mesozoicPeriod: .jurassic),
        Entry(slug: "brontosaurus", displayName: "Brontosaurus", icon: "🦕", speed: 13.5, racerAssetClade: "sauropod", mesozoicPeriod: .jurassic),
        Entry(slug: "trex", displayName: "T-Rex", icon: "🦖", speed: 25, racerAssetClade: "theropod", mesozoicPeriod: .cretaceous),
        Entry(slug: "triceratops", displayName: "Triceratops", icon: "🦏", speed: 25, racerAssetClade: "ceratopsian", mesozoicPeriod: .cretaceous),
        Entry(slug: "ankylosaurus", displayName: "Ankylosaurus", icon: "🛡️", speed: 4.5, racerAssetClade: "ankylosaur", mesozoicPeriod: .cretaceous),
        Entry(slug: "velociraptor", displayName: "Velociraptor", icon: "🦖", speed: 22.5, racerAssetClade: "theropod", mesozoicPeriod: .cretaceous),
        Entry(slug: "gallimimus", displayName: "Gallimimus", icon: "🦃", speed: 45, racerAssetClade: "ornithomimid", mesozoicPeriod: .cretaceous),
        Entry(slug: "albertosaurus", displayName: "Albertosaurus", icon: "🦖", speed: 25, racerAssetClade: "theropod", mesozoicPeriod: .cretaceous),
        Entry(slug: "parasaurolophus", displayName: "Parasaurolophus", icon: "🦕", speed: 22, racerAssetClade: "hadrosaur", mesozoicPeriod: .cretaceous),
        Entry(slug: "spinosaurus", displayName: "Spinosaurus", icon: "🦖", speed: 20, racerAssetClade: "spinosaurid", mesozoicPeriod: .cretaceous),
    ]

    static func mesozoicSpanForRacing(slug: String) -> Period? {
        allEntries.first(where: { $0.slug == slug })?.mesozoicPeriod
    }

    /// Builds `dino-racer-{slug}` from catalog portrait keys (`dino-trex`, …).
    static func dinoRacingAssetBase(fromCatalogImageName imageName: String) -> String? {
        guard imageName.hasPrefix("dino-") else { return nil }
        let portraitSlug = String(imageName.dropFirst("dino-".count))
        let racerSlug = portraitSlug == "t-rex" ? "trex" : portraitSlug
        guard allEntries.contains(where: { $0.slug == racerSlug }) else { return nil }
        return dinoRacingAssetBase(slug: racerSlug)
    }

    static func dinoRacingAssetBase(slug: String) -> String {
        "dino-racer-\(slug)"
    }

    /// Racing Dinosaurs requires ready + finish excited/exhausted poses (run/trip fall back when missing).
    static func hasCompleteDinosaurRacingAssetPack(slug: String) -> Bool {
        let base = dinoRacingAssetBase(slug: slug)
        return ImageAssetCache.imageExists(named: "\(base)-ready")
            && ImageAssetCache.imageExists(named: "\(base)-finish-excited")
            && ImageAssetCache.imageExists(named: "\(base)-finish-exhausted")
    }

    static func dinosaurRacersForRacing(mesozoicSpan: MesozoicSpan) -> [PoolEntry] {
        allEntries.compactMap { entry in
            let inPeriod: Bool = switch mesozoicSpan {
            case .jurassic: entry.mesozoicPeriod == .jurassic
            case .cretaceous: entry.mesozoicPeriod == .cretaceous
            case .both: true
            }
            guard inPeriod, hasCompleteDinosaurRacingAssetPack(slug: entry.slug) else { return nil }
            return PoolEntry(
                slug: entry.slug,
                displayName: entry.displayName,
                icon: entry.icon,
                speed: entry.speed,
                racerAssetClade: entry.racerAssetClade,
                racingAssetBase: dinoRacingAssetBase(slug: entry.slug)
            )
        }
    }
}
