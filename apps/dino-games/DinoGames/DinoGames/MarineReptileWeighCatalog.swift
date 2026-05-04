//
//  MarineReptileWeighCatalog.swift
//  DinoGames
//
//  Estimated masses (kg) for Weigh the Marine Reptile — sourced from project CSV
//  `json/marine-weight/marine_creatures_by_weight.csv` (game-relative weights for seesaw).
//

import Foundation

enum MarineReptileWeighCatalog {
    struct Entry: Hashable {
        let stableId: Int
        let imageAssetName: String
        let displayName: String
        let weightKg: Double

        /// Second path segment after `marine-` (mosa, plesio, ichthyo, …) — one creature per clade per round when possible.
        var cladeRaw: String {
            let parts = imageAssetName.split(separator: "-", omittingEmptySubsequences: false)
            guard parts.count >= 3, parts[0] == "marine" else { return "mosa" }
            return String(parts[1])
        }
    }

    static let allEntries: [Entry] = [
        .init(stableId: 4001, imageAssetName: "marine-ichthyo-shastasaurus", displayName: "Shastasaurus", weightKg: 70000.0),
        .init(stableId: 4002, imageAssetName: "marine-ichthyo-shonisaurus", displayName: "Shonisaurus", weightKg: 30000.0),
        .init(stableId: 4003, imageAssetName: "marine-mosa-mosasaurus", displayName: "Mosasaurus", weightKg: 20000.0),
        .init(stableId: 4004, imageAssetName: "marine-tylo-tylosaurus", displayName: "Tylosaurus", weightKg: 15000.0),
        .init(stableId: 4005, imageAssetName: "marine-plio-pliosaurus", displayName: "Pliosaurus", weightKg: 15000.0),
        .init(stableId: 4006, imageAssetName: "marine-mosa-hainosaurus", displayName: "Hainosaurus", weightKg: 12000.0),
        .init(stableId: 4007, imageAssetName: "marine-plio-kronosaurus", displayName: "Kronosaurus", weightKg: 11000.0),
        .init(stableId: 4008, imageAssetName: "marine-plio-sachicasaurus", displayName: "Sachicasaurus", weightKg: 10000.0),
        .init(stableId: 4009, imageAssetName: "marine-ichthyo-temnodontosaurus", displayName: "Temnodontosaurus", weightKg: 8000.0),
        .init(stableId: 4010, imageAssetName: "marine-plio-brachauchenius", displayName: "Brachauchenius", weightKg: 8000.0),
        .init(stableId: 4011, imageAssetName: "marine-mosa-prognathodon", displayName: "Prognathodon", weightKg: 7000.0),
        .init(stableId: 4012, imageAssetName: "marine-plio-megacephalosaurus", displayName: "Megacephalosaurus", weightKg: 6000.0),
        .init(stableId: 4013, imageAssetName: "marine-mosa-thalassotitan", displayName: "Thalassotitan", weightKg: 6000.0),
        .init(stableId: 4014, imageAssetName: "marine-mosa-plotosaurus", displayName: "Plotosaurus", weightKg: 5000.0),
        .init(stableId: 4015, imageAssetName: "marine-ichthyo-cymbospondylus", displayName: "Cymbospondylus", weightKg: 4000.0),
        .init(stableId: 4016, imageAssetName: "marine-mosa-khinjaria", displayName: "Khinjaria", weightKg: 4000.0),
        .init(stableId: 4017, imageAssetName: "marine-plio-rhomaleosaurus", displayName: "Rhomaleosaurus", weightKg: 3500.0),
        .init(stableId: 4018, imageAssetName: "marine-ichthyo-platypterygius", displayName: "Platypterygius", weightKg: 3000.0),
        .init(stableId: 4019, imageAssetName: "marine-plio-simolestes", displayName: "Simolestes", weightKg: 3000.0),
        .init(stableId: 4020, imageAssetName: "marine-plio-liopleurodon", displayName: "Liopleurodon", weightKg: 3000.0),
        .init(stableId: 4021, imageAssetName: "marine-plesio-styxosaurus", displayName: "Styxosaurus", weightKg: 3000.0),
        .init(stableId: 4022, imageAssetName: "marine-tylo-kaikaifilu", displayName: "Kaikaifilu", weightKg: 3000.0),
        .init(stableId: 4023, imageAssetName: "marine-hali-pluridens", displayName: "Pluridens", weightKg: 3000.0),
        .init(stableId: 4024, imageAssetName: "marine-ichthyo-brachypterygius", displayName: "Brachypterygius", weightKg: 3000.0),
        .init(stableId: 4025, imageAssetName: "marine-plesio-elasmosaurus", displayName: "Elasmosaurus", weightKg: 2500.0),
        .init(stableId: 4026, imageAssetName: "marine-plesio-thalassomedon", displayName: "Thalassomedon", weightKg: 2500.0),
        .init(stableId: 4027, imageAssetName: "marine-plesio-hydrotherosaurus", displayName: "Hydrotherosaurus", weightKg: 2500.0),
        .init(stableId: 4028, imageAssetName: "marine-testu-archelon", displayName: "Archelon", weightKg: 2200.0),
        .init(stableId: 4029, imageAssetName: "marine-plesio-woolungasaurus", displayName: "Woolungasaurus", weightKg: 2000.0),
        .init(stableId: 4030, imageAssetName: "marine-plesio-mauisaurus", displayName: "Mauisaurus", weightKg: 2000.0),
        .init(stableId: 4031, imageAssetName: "marine-plesio-aphrosaurus", displayName: "Aphrosaurus", weightKg: 2000.0),
        .init(stableId: 4032, imageAssetName: "marine-mosa-globidens", displayName: "Globidens", weightKg: 1500.0),
        .init(stableId: 4033, imageAssetName: "marine-mosa-megapterygius", displayName: "Megapterygius", weightKg: 1500.0),
        .init(stableId: 4034, imageAssetName: "marine-plesio-muraenosaurus", displayName: "Muraenosaurus", weightKg: 1500.0),
        .init(stableId: 4035, imageAssetName: "marine-ichthyo-caypullisaurus", displayName: "Caypullisaurus", weightKg: 1500.0),
        .init(stableId: 4036, imageAssetName: "marine-ichthyo-eurhinosaurus", displayName: "Eurhinosaurus", weightKg: 1200.0),
        .init(stableId: 4037, imageAssetName: "marine-ichthyo-kyhytysuka", displayName: "Kyhytysuka", weightKg: 1200.0),
        .init(stableId: 4038, imageAssetName: "marine-plesio-polycotylus", displayName: "Polycotylus", weightKg: 1000.0),
        .init(stableId: 4039, imageAssetName: "marine-testu-protostega", displayName: "Protostega", weightKg: 1000.0),
        .init(stableId: 4040, imageAssetName: "marine-pliop-plioplatecarpus", displayName: "Plioplatecarpus", weightKg: 1000.0),
        .init(stableId: 4041, imageAssetName: "marine-plesio-attenborosaurus", displayName: "Attenborosaurus", weightKg: 1000.0),
        .init(stableId: 4042, imageAssetName: "marine-mosa-gavialimimus", displayName: "Gavialimimus", weightKg: 1000.0),
        .init(stableId: 4043, imageAssetName: "marine-ichthyo-grendelius", displayName: "Grendelius", weightKg: 1000.0),
        .init(stableId: 4044, imageAssetName: "marine-ichthyo-ophthalmosaurus", displayName: "Ophthalmosaurus", weightKg: 1000.0),
        .init(stableId: 4045, imageAssetName: "marine-tylo-taniwhasaurus", displayName: "Taniwhasaurus", weightKg: 1000.0),
        .init(stableId: 4046, imageAssetName: "marine-thala-dakosaurus", displayName: "Dakosaurus", weightKg: 900.0),
        .init(stableId: 4047, imageAssetName: "marine-plesio-cryptoclidus", displayName: "Cryptoclidus", weightKg: 800.0),
        .init(stableId: 4048, imageAssetName: "marine-teleo-xiphactinus", displayName: "Xiphactinus", weightKg: 800.0),
        .init(stableId: 4049, imageAssetName: "marine-mosa-pannoniasaurus", displayName: "Pannoniasaurus", weightKg: 800.0),
        .init(stableId: 4050, imageAssetName: "marine-pliop-yaguarasaurus", displayName: "Yaguarasaurus", weightKg: 600.0),
        .init(stableId: 4051, imageAssetName: "marine-ichthyo-stenopterygius", displayName: "Stenopterygius", weightKg: 600.0),
        .init(stableId: 4052, imageAssetName: "marine-plio-peloneustes", displayName: "Peloneustes", weightKg: 500.0),
        .init(stableId: 4053, imageAssetName: "marine-pliop-platecarpus", displayName: "Platecarpus", weightKg: 500.0),
        .init(stableId: 4054, imageAssetName: "marine-plesio-dolichorhynchops", displayName: "Dolichorhynchops", weightKg: 500.0),
        .init(stableId: 4055, imageAssetName: "marine-plio-hauffiosaurus", displayName: "Hauffiosaurus", weightKg: 500.0),
        .init(stableId: 4056, imageAssetName: "marine-plesio-plesiosaurus", displayName: "Plesiosaurus", weightKg: 450.0),
        .init(stableId: 4057, imageAssetName: "marine-notho-nothosaurus", displayName: "Nothosaurus", weightKg: 400.0),
        .init(stableId: 4058, imageAssetName: "marine-thala-steneosaurus", displayName: "Steneosaurus", weightKg: 400.0),
        .init(stableId: 4059, imageAssetName: "marine-thala-metriorhynchus", displayName: "Metriorhynchus", weightKg: 300.0),
        .init(stableId: 4060, imageAssetName: "marine-plesio-microcleidus", displayName: "Microcleidus", weightKg: 300.0),
        .init(stableId: 4061, imageAssetName: "marine-mosa-clidastes", displayName: "Clidastes", weightKg: 200.0),
        .init(stableId: 4062, imageAssetName: "marine-basal-tanystropheus", displayName: "Tanystropheus", weightKg: 200.0),
        .init(stableId: 4063, imageAssetName: "marine-ichthyo-malawania", displayName: "Malawania", weightKg: 150.0),
        .init(stableId: 4064, imageAssetName: "marine-ichthyo-ichthyosaurus", displayName: "Ichthyosaurus", weightKg: 150.0),
        .init(stableId: 4065, imageAssetName: "marine-hali-halisaurus", displayName: "Halisaurus", weightKg: 150.0),
        .init(stableId: 4066, imageAssetName: "marine-hali-phosphosaurus", displayName: "Phosphosaurus", weightKg: 100.0),
        .init(stableId: 4067, imageAssetName: "marine-notho-placodus", displayName: "Placodus", weightKg: 100.0),
        .init(stableId: 4068, imageAssetName: "marine-testu-proganochelys", displayName: "Proganochelys", weightKg: 80.0),
        .init(stableId: 4069, imageAssetName: "marine-notho-henodus", displayName: "Henodus", weightKg: 50.0),
        .init(stableId: 4070, imageAssetName: "marine-teleo-gillicus", displayName: "Gillicus", weightKg: 40.0),
        .init(stableId: 4071, imageAssetName: "marine-ichthyo-mixosaurus", displayName: "Mixosaurus", weightKg: 20.0),
        .init(stableId: 4072, imageAssetName: "marine-teleo-enchodus", displayName: "Enchodus", weightKg: 15.0),
        .init(stableId: 4073, imageAssetName: "marine-mosa-dallasaurus", displayName: "Dallasaurus", weightKg: 15.0),
        .init(stableId: 4074, imageAssetName: "marine-mosa-xenodens", displayName: "Xenodens", weightKg: 10.0),
        .init(stableId: 4075, imageAssetName: "marine-basal-hupehsuchus", displayName: "Hupehsuchus", weightKg: 10.0),
        .init(stableId: 4076, imageAssetName: "marine-basal-judeasaurus", displayName: "Judeasaurus", weightKg: 10.0),
        .init(stableId: 4077, imageAssetName: "marine-basal-mesosaurus", displayName: "Mesosaurus", weightKg: 10.0),
        .init(stableId: 4078, imageAssetName: "marine-mosa-aigialosaurus", displayName: "Aigialosaurus", weightKg: 10.0),
        .init(stableId: 4079, imageAssetName: "marine-basal-dolichosaurus", displayName: "Dolichosaurus", weightKg: 5.0),
        .init(stableId: 4080, imageAssetName: "marine-basal-mesoleptos", displayName: "Mesoleptos", weightKg: 5.0),
    ]

    static let weightKgByStableId: [Int: Double] = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.stableId, $0.weightKg) })

    static let weightKgByImageAsset: [String: Double] = Dictionary(uniqueKeysWithValues: allEntries.map { ($0.imageAssetName, $0.weightKg) })
}
