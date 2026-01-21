//
//  LandingView.swift
//  GroceryApp
//
//  Landing page with app image and first-time user instructions
//

import SwiftUI

struct LandingView: View {
    @State private var hasSeenLanding = UserDefaults.standard.bool(forKey: "hasSeenLanding")
    @State private var showingHelp = false
    @State private var showingStoreSelection = false
    @Environment(\.managedObjectContext) private var viewContext
    
    // Check if user has already selected stores
    private var hasSelectedStores: Bool {
        let selectedStores = UserDefaults.standard.stringArray(forKey: "selectedStoreNames") ?? []
        return !selectedStores.isEmpty
    }
    
    var body: some View {
        if hasSeenLanding {
            MainTabView()
                .environment(\.managedObjectContext, viewContext)
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App Image
                    Image("ShoppingKart_image")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                    
                    // App Title
                    Text("ShoppingKart")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Subtitle
                    Text("Your Smart Shopping Companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // First Time User Button
                    Button(action: {
                        showingHelp = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                            Text("First Time User?")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    // Get Started Button
                    Button(action: {
                        // If stores haven't been selected, show store selection first
                        if !hasSelectedStores {
                            showingStoreSelection = true
                        } else {
                            UserDefaults.standard.set(true, forKey: "hasSeenLanding")
                            hasSeenLanding = true
                        }
                    }) {
                        HStack {
                            Text("Get Started")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .fullScreenCover(isPresented: $showingStoreSelection) {
                StoreSelectionView(isUpdating: false, onComplete: {
                    showingStoreSelection = false
                    UserDefaults.standard.set(true, forKey: "hasSeenLanding")
                    hasSeenLanding = true
                })
                .environment(\.managedObjectContext, viewContext)
            }
        }
    }
}

#Preview {
    LandingView()
}
