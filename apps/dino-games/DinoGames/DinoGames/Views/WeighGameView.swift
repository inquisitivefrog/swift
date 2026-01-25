//
//  WeighGameView.swift
//  DinoGames
//
//  Created by Timothy Stilwell on 1/24/26.
//

import SwiftUI
import UIKit

// MARK: - Data Models

struct WeighableItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String? // Optional image name in Assets.xcassets
    let emoji: String // Emoji fallback
    let weight: Int // Weight value for comparison (1-8 scale, allows multiple items per side)
    let category: String // "dinosaur", "person", "vehicle", "building"
}

// MARK: - Game Configuration

struct WeighGameConfig {
    let id: String
    let title: String
    let introAudio: String
    let items: [WeighableItem]
    
    // Threshold for "nearly the same" weight (within this difference)
    let similarWeightThreshold: Int = 1
}

// MARK: - Main View

struct WeighGameView: View {
    @Binding var isPresented: Bool
    let gameConfig: WeighGameConfig
    
    @State private var selectedLeftItem: WeighableItem?
    @State private var selectedRightItem: WeighableItem?
    @State private var isWeighing = false
    @State private var seesawAngle: Double = 0 // -15 to +15 degrees
    @State private var leftItemOffset: CGFloat = 0
    @State private var rightItemOffset: CGFloat = 0
    @State private var leftItemOpacity: Double = 1.0
    @State private var showSpeedLines = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top padding to prevent truncation
                Spacer()
                    .frame(height: geometry.size.height * 0.05) // 5% padding at top
                
                // Top - Item grid (2 rows x 4 columns) - Can fit 6 per row but we have 8 items
                VStack(spacing: 10) {
                    // 2 rows x 4 columns grid (all 8 items visible)
                    VStack(spacing: 10) {
                        // Row 1: First 4 items
                        HStack(spacing: 10) {
                            ForEach(Array(gameConfig.items.prefix(4))) { item in
                                ItemCard(
                                    item: item,
                                    isSelected: selectedLeftItem?.id == item.id || selectedRightItem?.id == item.id,
                                    isDisabled: isWeighing || (selectedLeftItem != nil && selectedRightItem != nil)
                                ) {
                                    handleItemTap(item)
                                }
                            }
                        }
                        
                        // Row 2: Last 4 items
                        HStack(spacing: 10) {
                            ForEach(Array(gameConfig.items.suffix(4))) { item in
                                ItemCard(
                                    item: item,
                                    isSelected: selectedLeftItem?.id == item.id || selectedRightItem?.id == item.id,
                                    isDisabled: isWeighing || (selectedLeftItem != nil && selectedRightItem != nil)
                                ) {
                                    handleItemTap(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                }
                .frame(width: geometry.size.width)
                
                // Increased space between images and seesaw
                Spacer()
                    .frame(height: geometry.size.height * 0.15) // 15% space between images and seesaw
                
                // Bottom - Seesaw area (centered in remaining space)
                VStack {
                    Spacer()
                        .frame(minHeight: 10) // Small spacer
                    
                    ZStack {
                        // Seesaw base/pivot point
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 20, height: 20)
                            .offset(y: 20)
                        
                        // Seesaw board (wider for landscape)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.brown.opacity(0.8))
                            .frame(width: geometry.size.width * 0.6, height: 15)
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(y: 20)
                        
                        // Left seat (small line above seesaw end)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.brown.opacity(0.8))
                            .frame(width: 8, height: 25)
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(x: -(geometry.size.width * 0.15), y: 5)
                        
                        // Right seat (small line above seesaw end)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.brown.opacity(0.8))
                            .frame(width: 8, height: 25)
                            .rotationEffect(.degrees(seesawAngle), anchor: .center)
                            .offset(x: geometry.size.width * 0.15, y: 5)
                    
                        // Left side item (positioned higher to sit on seat)
                        if let leftItem = selectedLeftItem {
                            Group {
                                if let imageName = leftItem.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else {
                                    Text(leftItem.emoji)
                                        .font(.system(size: 80))
                                }
                            }
                            .offset(x: -(geometry.size.width * 0.15), y: leftItemOffset - 70)
                            .opacity(leftItemOpacity)
                            
                            // Speed lines for right side (when left is heavier)
                            if showSpeedLines && selectedRightItem != nil {
                                SpeedLinesView()
                                    .offset(x: geometry.size.width * 0.15, y: rightItemOffset - 70)
                            }
                        }
                        
                        // Right side item (positioned higher to sit on seat)
                        if let rightItem = selectedRightItem {
                            Group {
                                if let imageName = rightItem.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                } else {
                                    Text(rightItem.emoji)
                                        .font(.system(size: 80))
                                }
                            }
                            .offset(x: geometry.size.width * 0.15, y: rightItemOffset - 70)
                        }
                    }
                    .frame(height: 250) // Seesaw area height
                    
                    // Use remaining space at bottom (shifted down from top)
                    Spacer()
                }
                .frame(width: geometry.size.width)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
        .onAppear {
            // Force landscape orientation immediately
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
                // Fallback method - force rotation
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            }
        }
        .onDisappear {
            // Allow rotation back to portrait when leaving
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
    
    private func handleItemTap(_ item: WeighableItem) {
        guard !isWeighing else { return }
        
        if selectedLeftItem == nil {
            // Select left item and pause
            selectedLeftItem = item
            // Pause to let user see left selection
        } else if selectedRightItem == nil && selectedLeftItem?.id != item.id {
            // Select right item
            selectedRightItem = item
            // Pause 0.2 seconds after right selection, then weigh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.startWeighing()
            }
        }
    }
    
    private func startWeighing() {
        guard let left = selectedLeftItem,
              let right = selectedRightItem else { return }
        
        isWeighing = true
        let weightDiff = left.weight - right.weight
        
        // Pause 0.2 seconds before adjusting seesaw
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 1.5)) {
                if abs(weightDiff) <= gameConfig.similarWeightThreshold {
                    // Similar weight - slight tilt, one higher
                    if weightDiff > 0 {
                        seesawAngle = -3 // Slight tilt left (reversed)
                        rightItemOffset = -20 // Right item higher
                    } else {
                        seesawAngle = 3 // Slight tilt right (reversed)
                        leftItemOffset = -20 // Left item higher
                    }
                } else if weightDiff > 0 {
                    // Left is heavier - left side goes down (reversed direction)
                    seesawAngle = -15 // Tilt left (reversed)
                    leftItemOffset = 20 // Left item goes down
                    rightItemOffset = -20 // Right item goes up
                    showSpeedLines = true
                } else {
                    // Right is heavier - right side goes down, left launches up
                    seesawAngle = 15 // Tilt right (reversed)
                    rightItemOffset = 20 // Right item goes down
                    leftItemOffset = -150 // Launch up (from -70 base)
                    leftItemOpacity = 0 // Fade out
                }
            }
            
            // Pause 0.5 seconds after result to let user laugh/absorb
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + 0.5) {
                self.resetWeighing()
            }
        }
    }
    
    private func resetWeighing() {
        withAnimation {
            seesawAngle = 0
            leftItemOffset = 0
            rightItemOffset = 0
            leftItemOpacity = 1.0
            showSpeedLines = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedLeftItem = nil
            selectedRightItem = nil
            isWeighing = false
        }
    }
}

// MARK: - Components

struct ItemCard: View {
    let item: WeighableItem
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70) // Slightly smaller to fit better
            } else {
                Text(item.emoji)
                    .font(.system(size: 50)) // Smaller emoji to fit better
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .opacity(isDisabled && !isSelected ? 0.5 : 1.0)
        .disabled(isDisabled && !isSelected)
    }
}

struct SpeedLinesView: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { _ in
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 2, height: 40)
            }
        }
    }
}

// MARK: - Game Configurations

struct WeighGameConfigs {
    static let weighDinosaur = WeighGameConfig(
        id: "weigh-dinosaur",
        title: "Weigh the Dinosaur!",
        introAudio: "game-intro-weigh",
        items: [
            // People - Realistic average weights (scaled for game)
            // Child (4-6 years): ~20 kg (44 lbs) average
            WeighableItem(id: 1, name: "Child", imageName: nil, emoji: "👶", weight: 1, category: "person"),
            
            // Parent (Mom): ~50 kg (110 lbs) - Lighter than ALL dinosaurs (realistic and respectful) 💪
            WeighableItem(id: 2, name: "Mom", imageName: nil, emoji: "👩", weight: 2, category: "person"),
            
            // Dinosaurs - Scientific weight estimates (scaled for game)
            // Stegosaurus: ~1,600 kg (1.6 metric tons) - lightest dinosaur, but still heavier than people
            WeighableItem(id: 3, name: "Stegosaurus", imageName: "dino-stegosaurus", emoji: "🦎", weight: 3, category: "dinosaur"),
            
            // Vehicle - Average car weight
            // Car: ~1,750 kg (1.75 metric tons)
            WeighableItem(id: 4, name: "Car", imageName: nil, emoji: "🚗", weight: 4, category: "vehicle"),
            
            // Triceratops: ~7,500 kg (7.5 metric tons) average
            WeighableItem(id: 5, name: "Triceratops", imageName: "dino-triceratops", emoji: "🦏", weight: 5, category: "dinosaur"),
            
            // T-Rex: ~10,000 kg (10 metric tons) - heaviest dinosaur
            WeighableItem(id: 6, name: "T-Rex", imageName: "dino-trex", emoji: "🦖", weight: 6, category: "dinosaur"),
            
            // Parent (Dad): ~70 kg (154 lbs) - SILLINESS: Dad outweighs the heaviest dinosaur! 🎭
            WeighableItem(id: 7, name: "Dad", imageName: nil, emoji: "👨", weight: 7, category: "person"),
            
            // Building - Small house structure/building materials
            // House: Represents a small structure for game purposes
            WeighableItem(id: 8, name: "House", imageName: nil, emoji: "🏠", weight: 8, category: "building")
        ]
    )
}

#Preview {
    WeighGameView(isPresented: .constant(true), gameConfig: WeighGameConfigs.weighDinosaur)
}
