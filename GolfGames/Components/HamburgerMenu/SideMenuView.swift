//
//  SideMenuView.swift
//  GolfGames
//
//  Created by Mike Dietrich on 8/11/24.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var roundViewModel: RoundViewModel
    @Binding var navigateToInitialView: Bool
    @State private var showDiscardAlert = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuHeader
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    menuItems
                }
                .padding(.top, 30)
            }
            
            Spacer()
            
            discardButton
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showDiscardAlert) {
            Alert(
                title: Text("Discard Round"),
                message: Text("Are you sure you want to discard the round?"),
                primaryButton: .destructive(Text("Discard")) {
                    discardRound()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var menuHeader: some View {
        HStack {
            Image(systemName: "figure.golf")
                .foregroundColor(.blue)
                .imageScale(.large)
            Text("Menu")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 25) {
            menuButton(icon: "list.bullet", text: "View Scorecard") {
                // Add action for viewing scorecard
            }
        }
    }
    
    private func menuButton(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .imageScale(.large)
                    .frame(width: 30)
                Text(text)
                    .foregroundColor(.primary)
                    .font(.headline)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .cornerRadius(10)
    }
    
    private var discardButton: some View {
        Button(action: {
            showDiscardAlert = true
        }) {
            HStack(spacing: 16) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .imageScale(.large)
                Text("Discard Round")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(10)
        }
        .padding(.bottom, 100)
    }
    
    private func discardRound() {
        roundViewModel.clearRoundData()
        navigateToInitialView = true
        isShowing = false
    }
}