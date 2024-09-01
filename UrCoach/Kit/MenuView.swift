// Copyright 2024 Stephen E. Bensley
//
// This file is licensed under the MIT License. You may obtain a copy of the
// license at https://github.com/stephenbensley/UrCoach/blob/main/LICENSE.
//

import SwiftUI

// An item in the main menu
struct MenuItem: View {
    let text: LocalizedStringKey
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Helvetica", fixedSize: 20))
                .frame(width: 250)
                .padding()
                .background(.gameboardFill)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(.gameboardStroke, lineWidth: 5)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(2)
    }
}

// Presents the main menu of options for the user to choose from.
struct MenuView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.openURL) private var openURL
    private var delegate: CheckersGame
    private var changeView: ChangeView
    @State private var showAbout = false
    
    var scale: CGFloat {
        return sizeClass == .compact ? 1.0 : 1.5
    }
    
    init(delegate: some CheckersGame, changeView: @escaping ChangeView) {
        self.delegate = delegate
        self.changeView = changeView
    }

    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text(delegate.name)
                    .font(.custom("Helvetica-Bold", fixedSize: 40))
                    .foregroundStyle(.white)
                Text(delegate.description)
                    .font(.custom("Helvetica", fixedSize: 18))
                    .foregroundStyle(.white)
                    .padding(.bottom)
                MenuItem(text: "White vs. Computer") {
                    delegate.newGame(white: .human, black: .computer)
                    changeView(.game)
                }
                MenuItem(text: "Black vs. Computer") {
                    delegate.newGame(white: .computer, black: .human)
                    changeView(.game)
                }
                MenuItem(text: "Player vs. Player") {
                    delegate.newGame(white: .human, black: .human)
                    changeView(.game)
                }
                MenuItem(text: "Resume Game") {
                    changeView(.game)
                }
                MenuItem(text: "How to Play") {
                    showAbout = true
                }
                MenuItem(text: "Privacy Policy  \(Image(systemName: "link"))") {
                    if let url = URL(string: "https://stephenbensley.github.io/Queah/privacy.html") {
                        openURL(url)
                    }
                }
                
            }
            .scaleEffect(scale, anchor: .center)
            Spacer()
            Spacer()
        }
        .sheet(isPresented: $showAbout) { RulesView(changeView: { _ in }) }
    }
}


#Preview {
    MenuView(delegate: MockDelegate(), changeView: { _ in } )
}
