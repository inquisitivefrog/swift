//
//  ImageAssetCache.swift
//  DinoGames
//
//  Checks image existence without loading. UIImage(named:) loads and decodes
//  full images into memory; using it for existence checks caused memory pressure
//  and app termination on device. We use a pre-computed set from the asset
//  catalog instead (ImageAssetNames.knownAssets).
//

import UIKit

enum ImageAssetCache {
    /// Returns true if the named image exists in the asset catalog.
    /// Uses a static set of known asset names—no image loading or decoding.
    /// Regenerate ImageAssetNames.generated.swift when adding new assets.
    static func imageExists(named name: String) -> Bool {
        ImageAssetNames.knownAssets.contains(name)
    }
}
