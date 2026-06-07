//
//  MarineReptileLengthCatalog.swift
//  DinoGames
//
//  Approximate total length (m, snout to tail tip) for Which Marine Reptile Is Longer.
//  Hand-tuned educational values from commonly cited adult reconstruction ranges.
//

import Foundation

enum MarineReptileLengthCatalog {
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

    static func totalLengthMeters(forCreatureId id: Int, in creatures: [Dinosaur]) -> Double? {
        guard let imageName = creatures.first(where: { $0.id == id })?.imageName else { return nil }
        return totalLengthMeters(forImageName: imageName)
    }
}
