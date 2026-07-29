//
//  FrenchVocabulary.swift
//  Games
//

import Foundation

enum FrenchCategory: String, CaseIterable, Identifiable, Hashable {
    case numbers
    case shapes
    case colors
    case alphabet
    case weather
    case datesAndTime
    case money
    case family
    case home
    case occupations
    case nationalities

    var id: String { rawValue }

    var title: String {
        switch self {
        case .numbers: "Numbers"
        case .shapes: "Shapes"
        case .colors: "Colors"
        case .alphabet: "Alphabet"
        case .weather: "Weather"
        case .datesAndTime: "Dates & Time"
        case .money: "Money"
        case .family: "Family"
        case .home: "Home"
        case .occupations: "Occupations"
        case .nationalities: "Nationalities"
        }
    }

    var systemImage: String {
        switch self {
        case .numbers: "textformat.123"
        case .shapes: "triangle"
        case .colors: "paintpalette"
        case .alphabet: "textformat.abc"
        case .weather: "cloud.sun"
        case .datesAndTime: "calendar"
        case .money: "eurosign.circle"
        case .family: "figure.2.and.child.holdinghands"
        case .home: "house"
        case .occupations: "briefcase"
        case .nationalities: "globe"
        }
    }

    var words: [FrenchWord] {
        FrenchVocabulary.words(for: self)
    }
}

struct FrenchWord: Identifiable, Hashable {
    let id: String
    let french: String
    let english: String

    init(french: String, english: String) {
        self.id = "\(french)|\(english)"
        self.french = french
        self.english = english
    }
}

enum FrenchVocabulary {
    static func words(for category: FrenchCategory) -> [FrenchWord] {
        switch category {
        case .numbers:
            wordList([
                ("un", "one"),
                ("deux", "two"),
                ("trois", "three"),
                ("quatre", "four"),
                ("cinq", "five"),
                ("six", "six"),
                ("sept", "seven"),
                ("huit", "eight"),
                ("neuf", "nine"),
                ("dix", "ten"),
            ])
        case .shapes:
            wordList([
                ("cercle", "circle"),
                ("carré", "square"),
                ("triangle", "triangle"),
                ("rectangle", "rectangle"),
                ("ovale", "oval"),
                ("diamant", "diamond"),
                ("étoile", "star"),
                ("cœur", "heart"),
                ("croissant", "crescent"),
                ("hexagone", "hexagon"),
            ])
        case .colors:
            wordList([
                ("rouge", "red"),
                ("bleu", "blue"),
                ("vert", "green"),
                ("jaune", "yellow"),
                ("noir", "black"),
                ("blanc", "white"),
                ("orange", "orange"),
                ("rose", "pink"),
                ("violet", "purple"),
                ("gris", "gray"),
            ])
        case .alphabet:
            wordList([
                ("A (a)", "A"),
                ("B (bé)", "B"),
                ("C (cé)", "C"),
                ("D (dé)", "D"),
                ("E (e)", "E"),
                ("F (effe)", "F"),
                ("G (gé)", "G"),
                ("H (ache)", "H"),
                ("I (i)", "I"),
                ("J (ji)", "J"),
            ])
        case .weather:
            wordList([
                ("soleil", "sun"),
                ("pluie", "rain"),
                ("nuage", "cloud"),
                ("neige", "snow"),
                ("vent", "wind"),
                ("orage", "storm"),
                ("brouillard", "fog"),
                ("chaud", "hot"),
                ("froid", "cold"),
                ("parapluie", "umbrella"),
            ])
        case .datesAndTime:
            wordList([
                ("aujourd'hui", "today"),
                ("demain", "tomorrow"),
                ("hier", "yesterday"),
                ("matin", "morning"),
                ("soir", "evening"),
                ("heure", "hour"),
                ("minute", "minute"),
                ("lundi", "Monday"),
                ("janvier", "January"),
                ("année", "year"),
            ])
        case .money:
            wordList([
                ("euro", "euro"),
                ("centime", "cent"),
                ("argent", "money"),
                ("prix", "price"),
                ("cher", "expensive"),
                ("bon marché", "inexpensive"),
                ("payer", "to pay"),
                ("acheter", "to buy"),
                ("monnaie", "change"),
                ("portefeuille", "wallet"),
            ])
        case .family:
            wordList([
                ("mère", "mother"),
                ("père", "father"),
                ("frère", "brother"),
                ("sœur", "sister"),
                ("enfant", "child"),
                ("grand-père", "grandfather"),
                ("grand-mère", "grandmother"),
                ("oncle", "uncle"),
                ("tante", "aunt"),
                ("cousin", "cousin (male)"),
            ])
        case .home:
            wordList([
                ("maison", "house"),
                ("appartement", "apartment"),
                ("cuisine", "kitchen"),
                ("chambre", "bedroom"),
                ("salle de bain", "bathroom"),
                ("salon", "living room"),
                ("porte", "door"),
                ("fenêtre", "window"),
                ("table", "table"),
                ("chaise", "chair"),
            ])
        case .occupations:
            wordList([
                ("médecin", "doctor"),
                ("enseignant", "teacher"),
                ("ingénieur", "engineer"),
                ("cuisinier", "cook"),
                ("policier", "police officer"),
                ("infirmier", "nurse"),
                ("avocat", "lawyer"),
                ("fermier", "farmer"),
                ("artiste", "artist"),
                ("étudiant", "student"),
            ])
        case .nationalities:
            wordList([
                ("français", "French"),
                ("américain", "American"),
                ("canadien", "Canadian"),
                ("britannique", "British"),
                ("espagnol", "Spanish"),
                ("italien", "Italian"),
                ("allemand", "German"),
                ("mexicain", "Mexican"),
                ("japonais", "Japanese"),
                ("chinois", "Chinese"),
            ])
        }
    }

    private static func wordList(_ pairs: [(String, String)]) -> [FrenchWord] {
        precondition(pairs.count == 10, "Each category must have exactly 10 words")
        return pairs.map { FrenchWord(french: $0.0, english: $0.1) }
    }
}
