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
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var navigateToInitialView: Bool
    @State private var showDiscardAlert = false
    @State private var showFriendsSheet = false
    @Environment(\.colorScheme) var colorScheme
    var showDiscardButton: Bool
    @GestureState private var dragOffset: CGFloat = 0

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
            
            if showDiscardButton {
                discardButton
                    .padding(.bottom, 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(backgroundColor)
        .edgesIgnoringSafeArea(.all)
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    if value.translation.width < 0 {
                        state = value.translation.width
                    }
                }
                .onEnded { value in
                    if value.translation.width < -50 {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
        )
        .alert("Discard Round", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Discard", role: .destructive) {
                discardRound()
            }
        } message: {
            Text("Are you sure you want to discard the round?")
        }
        .sheet(isPresented: $showFriendsSheet) {
            FriendsListView(
                viewModel: FriendsViewModel(userId: authViewModel.currentUser?.id ?? ""),
                selectedFriends: .constant([]),
                onDone: {
                    showFriendsSheet = false
                    isShowing = false
                },
                allowSelection: false
            ).environmentObject(authViewModel)
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
            if roundViewModel.roundId == nil {
                menuButton(icon: "person.2", text: "Friends") {
                    print("Friends button tapped")
                    showFriendsSheet = true
                }
            }
            // menuButton(icon: "list.bullet", text: "View Scorecard") {
            //     // Add action for viewing scorecard
            // }
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
            print("Discard button tapped")
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
    }
    
    private func discardRound() {
        print("Discarding round")
        roundViewModel.clearRoundData()
        navigateToInitialView = true
        isShowing = false
    }
}
