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
    private var appModel: UrModel
    private var changeView: ChangeView
    
    var scale: CGFloat {
        return sizeClass == .compact ? 1.0 : 1.5
    }
    
    init(appModel: UrModel, changeView: @escaping ChangeView) {
        self.appModel = appModel
        self.changeView = changeView
    }

    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Queah")
                    .font(.custom("Helvetica-Bold", fixedSize: 40))
                    .foregroundStyle(.white)
                Text("A strategy game from Liberia")
                    .font(.custom("Helvetica", fixedSize: 18))
                    .foregroundStyle(.white)
                    .padding(.bottom)
                MenuItem(text: "White vs. Computer") {
                    appModel.newGame(white: .human, black: .computer)
                    changeView(.game)
                }
                MenuItem(text: "Black vs. Computer") {
                    appModel.newGame(white: .computer, black: .human)
                    changeView(.game)
                }
                MenuItem(text: "Player vs. Player") {
                    appModel.newGame(white: .human, black: .human)
                    changeView(.game)
                }
                MenuItem(text: "Resume Game") {
                    changeView(.game)
                }
                MenuItem(text: "How to Play") {
                    changeView(.rules)
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
    }
}
