//
//  MarineReptileCreaturePools.swift
//  DinoGames
//
//  Marine reptile catalogs for guess games (silhouettes: mosa-*, plesio-*, ichthyo-*).
//  IDs 201+ avoid overlap with land dinosaurs (1–57) and pterosaurs (101–110).
//

import Foundation

enum MarineReptileCreaturePools {
    static let allMosasaurs: [Dinosaur] = [
        Dinosaur(id: 201, name: "Mosasaurus", icon: "🌊", imageName: "mosa-mosasaurus", characteristicIds: []),
        Dinosaur(id: 202, name: "Tylosaurus", icon: "🌊", imageName: "mosa-tylosaurus", characteristicIds: []),
        Dinosaur(id: 203, name: "Dallasaurus", icon: "🌊", imageName: "mosa-dallasaurus", characteristicIds: []),
    ]

    static let allPlesiosaurs: [Dinosaur] = [
        Dinosaur(id: 211, name: "Plesiosaurus", icon: "🌊", imageName: "plesio-plesiosaurus", characteristicIds: []),
        Dinosaur(id: 212, name: "Elasmosaurus", icon: "🌊", imageName: "plesio-elasmosaurus", characteristicIds: []),
        Dinosaur(id: 213, name: "Liopleurodon", icon: "🌊", imageName: "plesio-liopleurodon", characteristicIds: []),
        Dinosaur(id: 214, name: "Cryptoclidus", icon: "🌊", imageName: "plesio-cryptoclidus", characteristicIds: []),
        Dinosaur(id: 215, name: "Polycotylus", icon: "🌊", imageName: "plesio-polycotylus", characteristicIds: []),
    ]

    static let allIchthyosaurs: [Dinosaur] = [
        Dinosaur(id: 221, name: "Ichthyosaurus", icon: "🌊", imageName: "ichthyo-ichthyosaurus", characteristicIds: []),
        Dinosaur(id: 222, name: "Temnodontosaurus", icon: "🌊", imageName: "ichthyo-temnodontosaurus", characteristicIds: []),
        Dinosaur(id: 223, name: "Eurhinosaurus", icon: "🌊", imageName: "ichthyo-eurhinosaurus", characteristicIds: []),
    ]
}
