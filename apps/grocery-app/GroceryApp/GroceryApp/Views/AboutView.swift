//
//  AboutView.swift
//  GroceryApp
//
//  About/Info view showing app version and ownership
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text("Grocery Shopping")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section("Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(buildNumber)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Copyright")
                    Spacer()
                    Text(copyrightText)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Developer") {
                HStack {
                    Text("Author")
                    Spacer()
                    Text("Timothy Stilwell")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Get app version from Info.plist
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Get build number from Info.plist
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // Copyright text
    private var copyrightText: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© \(year) Timothy Stilwell"
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
