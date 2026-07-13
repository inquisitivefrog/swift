//
//  LandDinosaurData.swift
//  DinoGames
//
//  Land dinosaur pool and per-id tables shared by matching, guess, weigh, and other games.
//

import Foundation

enum LandDinosaurData {
    // Full pool of available dinosaurs (matches app assets and docs/DINOSAUR_CHARACTERISTICS_4-6.md)
    static let allDinosaurs: [Dinosaur] = [
        Dinosaur(id: 1, name: "T-Rex", icon: "🦖", imageName: "dino-trex", characteristicIds: [1, 24, 119, 120]),
        Dinosaur(id: 2, name: "Triceratops", icon: "🦏", imageName: "dino-triceratops", characteristicIds: [3, 4, 117, 121, 122]),
        Dinosaur(id: 3, name: "Stegosaurus", icon: "🦎", imageName: "dino-stegosaurus", characteristicIds: [5, 113, 114, 196]),
        Dinosaur(id: 4, name: "Velociraptor", icon: "🦖", imageName: "dino-velociraptor", characteristicIds: [6, 7, 23, 123, 124]),
        Dinosaur(id: 5, name: "Therizinosaurus", icon: "🦕", imageName: "dino-therizinosaurus", characteristicIds: [8, 9, 125, 126]),
        Dinosaur(id: 6, name: "Spinosaurus", icon: "🦖", imageName: "dino-spinosaurus", characteristicIds: [10, 11, 115, 127, 128]),
        Dinosaur(id: 7, name: "Apatosaurus", icon: "🦕", imageName: "dino-apatosaurus", characteristicIds: [12, 13, 116, 129]),
        Dinosaur(id: 8, name: "Ankylosaurus", icon: "🛡️", imageName: "dino-ankylosaurus", characteristicIds: [14, 15, 130, 131]),
        Dinosaur(id: 9, name: "Corythosaurus", icon: "🦆", imageName: "dino-corythosaurus", characteristicIds: [16, 17, 132, 133]),
        Dinosaur(id: 10, name: "Parasaurolophus", icon: "🦆", imageName: "dino-parasaurolophus", characteristicIds: [18, 19, 134, 135]),
        Dinosaur(id: 11, name: "Iguanodon", icon: "🦎", imageName: "dino-iguanodon", characteristicIds: [20, 118, 136, 137]),
        Dinosaur(id: 12, name: "Troodon", icon: "🦉", imageName: "dino-troodon", characteristicIds: [21, 22, 138]),
        Dinosaur(id: 13, name: "Edmontosaurus", icon: "🦆", imageName: "dino-edmontosaurus", characteristicIds: [25, 27, 139]),
        Dinosaur(id: 14, name: "Camarasaurus", icon: "🦕", imageName: "dino-camarasaurus", characteristicIds: [45, 46, 140, 197]),
        Dinosaur(id: 15, name: "Dryosaurus", icon: "🦎", imageName: "dino-dryosaurus", characteristicIds: [28, 41, 141, 142]),
        Dinosaur(id: 16, name: "Gallimimus", icon: "🦖", imageName: "dino-gallimimus", characteristicIds: [47, 48, 143]),
        Dinosaur(id: 17, name: "Pachycephalosaurus", icon: "🦎", imageName: "dino-pachycephalosaurus", characteristicIds: [49, 50, 144]),
        Dinosaur(id: 18, name: "Albertosaurus", icon: "🦖", imageName: "dino-albertosaurus", characteristicIds: [51, 52, 145]),
        Dinosaur(id: 19, name: "Anchiornis", icon: "🦅", imageName: "dino-anchiornis", characteristicIds: [53, 54, 146]),
        Dinosaur(id: 20, name: "Archaeopteryx", icon: "🦅", imageName: "dino-archaeopteryx", characteristicIds: [55, 56, 147]),
        Dinosaur(id: 21, name: "Argentinosaurus", icon: "🦕", imageName: "dino-argentinosaurus", characteristicIds: [57, 58, 148, 149]),
        Dinosaur(id: 22, name: "Baryonyx", icon: "🦖", imageName: "dino-baryonyx", characteristicIds: [59, 60, 150, 151]),
        Dinosaur(id: 23, name: "Brachiosaurus", icon: "🦕", imageName: "dino-brachiosaurus", characteristicIds: [61, 62, 152]),
        Dinosaur(id: 24, name: "Ceratosaurus", icon: "🦖", imageName: "dino-ceratosaurus", characteristicIds: [63, 64, 153, 154]),
        Dinosaur(id: 25, name: "Chasmosaurus", icon: "🦏", imageName: "dino-chasmosaurus", characteristicIds: [65, 66, 155, 156, 157]),
        Dinosaur(id: 26, name: "Compsognathus", icon: "🦖", imageName: "dino-compsognathus", characteristicIds: [67, 68]),
        Dinosaur(id: 27, name: "Deinonychus", icon: "🦖", imageName: "dino-deinonychus", characteristicIds: [69, 70, 158, 159]),
        Dinosaur(id: 28, name: "Diplodocus", icon: "🦕", imageName: "dino-diplodocus", characteristicIds: [71, 72, 160]),
        Dinosaur(id: 29, name: "Dromaeosaurus", icon: "🦖", imageName: "dino-dromaeosaurus", characteristicIds: [73, 74, 161]),
        Dinosaur(id: 30, name: "Eosinopteryx", icon: "🦅", imageName: "dino-eosinopteryx", characteristicIds: [75, 76]),
        Dinosaur(id: 31, name: "Giganotosaurus", icon: "🦖", imageName: "dino-giganotosaurus", characteristicIds: [77, 78, 162]),
        Dinosaur(id: 32, name: "Kosmoceratops", icon: "🦏", imageName: "dino-kosmoceratops", characteristicIds: [79, 80, 163, 164, 165]),
        Dinosaur(id: 33, name: "Microraptor", icon: "🦅", imageName: "dino-microraptor", characteristicIds: [81, 82, 166]),
        Dinosaur(id: 34, name: "Pedopenna", icon: "🦅", imageName: "dino-pedopenna", characteristicIds: [83, 84, 167]),
        Dinosaur(id: 35, name: "Torosaurus", icon: "🦏", imageName: "dino-torosaurus", characteristicIds: [85, 86, 168, 169, 170]),
        Dinosaur(id: 36, name: "Utahraptor", icon: "🦖", imageName: "dino-utahraptor", characteristicIds: [87, 88, 171, 172]),
        Dinosaur(id: 37, name: "Xiaotingia", icon: "🦅", imageName: "dino-xiaotingia", characteristicIds: [89, 90, 173]),
        Dinosaur(id: 38, name: "Masiakasaurus", icon: "🦖", imageName: "dino-masiakasaurus", characteristicIds: [29, 42, 174]),
        Dinosaur(id: 39, name: "Torvosaurus", icon: "🦖", imageName: "dino-torvosaurus", characteristicIds: [30, 43, 175]),
        Dinosaur(id: 40, name: "Rapetosaurus", icon: "🦕", imageName: "dino-rapetosaurus", characteristicIds: [31, 32, 176, 195]),
        Dinosaur(id: 41, name: "Majungasaurus", icon: "🦖", imageName: "dino-majungasaurus", characteristicIds: [33, 44, 177]),
        Dinosaur(id: 42, name: "Allosaurus", icon: "🦖", imageName: "dino-allosaurus", characteristicIds: [34, 35, 178]),
        Dinosaur(id: 43, name: "Oviraptor", icon: "🦅", imageName: "dino-oviraptor", characteristicIds: [36, 37, 179]),
        Dinosaur(id: 44, name: "Brontosaurus", icon: "🦕", imageName: "dino-brontosaurus", characteristicIds: [91, 92, 180]),
        Dinosaur(id: 45, name: "Kentrosaurus", icon: "🦎", imageName: "dino-kentrosaurus", characteristicIds: [93, 94, 181]),
        Dinosaur(id: 46, name: "Edmontonia", icon: "🛡️", imageName: "dino-edmontonia", characteristicIds: [95, 96, 182]),
        Dinosaur(id: 47, name: "Lambeosaurus", icon: "🦆", imageName: "dino-lambeosaurus", characteristicIds: [97, 98, 183, 184]),
        Dinosaur(id: 48, name: "Maiasaura", icon: "🦆", imageName: "dino-maiasaura", characteristicIds: [99, 100, 185, 186]),
        Dinosaur(id: 49, name: "Stegoceras", icon: "🦎", imageName: "dino-stegoceras", characteristicIds: [101, 102, 187]),
        Dinosaur(id: 50, name: "Stygimoloch", icon: "🦎", imageName: "dino-stygimoloch", characteristicIds: [103, 104]),
        Dinosaur(id: 51, name: "Nodosaurus", icon: "🛡️", imageName: "dino-nodosaurus", characteristicIds: [105, 106, 189]),
        Dinosaur(id: 52, name: "Huayangosaurus", icon: "🦎", imageName: "dino-huayangosaurus", characteristicIds: [107, 108, 190]),
        Dinosaur(id: 53, name: "Ouranosaurus", icon: "🦎", imageName: "dino-ouranosaurus", characteristicIds: [109, 110, 191, 192]),
        Dinosaur(id: 54, name: "Suchomimus", icon: "🦖", imageName: "dino-suchomimus", characteristicIds: [111, 112, 193, 194]),
        Dinosaur(id: 55, name: "Euoplocephalus", icon: "🛡️", imageName: "dino-euoplocephalus", characteristicIds: [198, 199]),
        Dinosaur(id: 56, name: "Polacanthus", icon: "🛡️", imageName: "dino-polacanthus", characteristicIds: [200, 201]),
        Dinosaur(id: 57, name: "Styracosaurus", icon: "🦏", imageName: "dino-styracosaurus", characteristicIds: [202, 203]),
        Dinosaur(id: 58, name: "Acrocanthosaurus", icon: "🦖", imageName: "dino-acrocanthosaurus", characteristicIds: [204, 205]),
        Dinosaur(id: 59, name: "Amargasaurus", icon: "🦕", imageName: "dino-amargasaurus", characteristicIds: [206, 207]),
        Dinosaur(id: 60, name: "Carcharodontosaurus", icon: "🦖", imageName: "dino-carcharodontosaurus", characteristicIds: [208, 209]),
        Dinosaur(id: 61, name: "Carnotaurus", icon: "🦖", imageName: "dino-carnotaurus", characteristicIds: [210, 211]),
        Dinosaur(id: 62, name: "Deinocheirus", icon: "🦆", imageName: "dino-deinocheirus", characteristicIds: [212, 213]),
        Dinosaur(id: 63, name: "Fukuiraptor", icon: "🦖", imageName: "dino-fukuiraptor", characteristicIds: [214, 215]),
        Dinosaur(id: 64, name: "Gasparinisaura", icon: "🦎", imageName: "dino-gasparinisaura", characteristicIds: [216, 217]),
        Dinosaur(id: 65, name: "Gigantoraptor", icon: "🦖", imageName: "dino-gigantoraptor", characteristicIds: [218, 219]),
        Dinosaur(id: 66, name: "Mamenchisaurus", icon: "🦕", imageName: "dino-mamenchisaurus", characteristicIds: [220, 221]),
        Dinosaur(id: 67, name: "Ornithomimus", icon: "🦖", imageName: "dino-ornithomimus", characteristicIds: [222, 223]),
        Dinosaur(id: 68, name: "Riparovenator", icon: "🦖", imageName: "dino-riparovenator", characteristicIds: [224, 225]),
        Dinosaur(id: 69, name: "Struthiomimus", icon: "🦖", imageName: "dino-struthiomimus", characteristicIds: [226, 227]),
    ]

    /// Five diet option labels for Dino Diets! (matches `dino-diets-*` imagesets).
    static let dinosaurDietTypes = ["Herbivore", "Carnivore", "Piscivore", "Insectivore", "Omnivore"]

    /// Spoken diet name under `Audio/Dino-Diets/dino-diet-{slug}.m4a`.
    static func dinosaurDietAudioKey(for dietType: String) -> String {
        "dino-diet-\(dietType.lowercased())"
    }

    /// Diet per dinosaur for Dino Diets! (Herbivore, Carnivore, Piscivore, Insectivore, Omnivore).
    static let dinosaurDietById: [Int: String] = [
        1: "Carnivore", 2: "Herbivore", 3: "Herbivore", 4: "Carnivore", 5: "Herbivore", 6: "Piscivore",
        7: "Herbivore", 8: "Herbivore", 9: "Herbivore", 10: "Herbivore", 11: "Herbivore", 12: "Carnivore",
        13: "Herbivore", 14: "Herbivore", 15: "Herbivore", 16: "Omnivore", 17: "Herbivore", 18: "Carnivore",
        19: "Carnivore", 20: "Carnivore", 21: "Herbivore", 22: "Piscivore", 23: "Herbivore", 24: "Carnivore",
        25: "Herbivore", 26: "Insectivore", 27: "Carnivore", 28: "Herbivore", 29: "Carnivore", 30: "Insectivore",
        31: "Carnivore", 32: "Herbivore", 33: "Carnivore", 34: "Insectivore", 35: "Herbivore", 36: "Carnivore",
        37: "Carnivore", 38: "Carnivore", 39: "Carnivore", 40: "Herbivore", 41: "Carnivore", 42: "Carnivore",
        43: "Omnivore", 44: "Herbivore", 45: "Herbivore", 46: "Herbivore", 47: "Herbivore", 48: "Herbivore",
        49: "Herbivore", 50: "Herbivore", 51: "Herbivore", 52: "Herbivore", 53: "Herbivore", 54: "Piscivore",
        55: "Herbivore", 56: "Herbivore", 57: "Herbivore", 58: "Carnivore", 59: "Herbivore", 60: "Carnivore",
        61: "Carnivore", 62: "Omnivore", 63: "Carnivore", 64: "Herbivore", 65: "Omnivore", 66: "Herbivore",
        67: "Omnivore", 68: "Piscivore", 69: "Omnivore",
    ]

    /// Estimated adult body mass in kg per dinosaur id. Used by Weigh and Balance games.
    static let dinosaurEstimatedWeightKgById: [Int: Double] = [
        1: 8_000,   2: 9_000,   3: 4_500,   4: 20,      5: 5_000,   6: 7_000,   7: 25_000,  8: 6_000,
        9: 3_500,   10: 2_700,  11: 4_500,  12: 50,     13: 4_000,  14: 15_000, 15: 100,    16: 400,
        17: 450,    18: 2_500,  19: 0.5,    20: 0.5,    21: 70_000, 22: 2_000,  23: 35_000, 24: 1_000,
        25: 3_000,  26: 3,      27: 70,     28: 15_000, 29: 25,     30: 0.5,    31: 13_000, 32: 2_500,
        33: 1,      34: 0.5,    35: 6_000,  36: 500,    37: 0.5,    38: 20,     39: 2_000,  40: 15_000,
        41: 1_500,  42: 2_000,  43: 40,     44: 18_000, 45: 2_000,  46: 3_000,  47: 3_500,  48: 3_000,
        49: 40,     50: 80,     51: 3_000,  52: 1_000,  53: 2_500,  54: 3_000,
        55: 2_500,  56: 1_000,  57: 2_700,  58: 6_000,  59: 5_000,  60: 8_000,  61: 1_500,  62: 6_000,
        63: 300,    64: 30,     65: 2_000,  66: 12_000, 67: 170,    68: 1_000,  69: 150,
    ]
}
