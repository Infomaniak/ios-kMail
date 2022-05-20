/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import MailResources
import SwiftUI

struct BottomCard<Content: View>: View {
    let content: Content
    @Binding var cardShown: Bool
    @Binding var cardDismissal: Bool
    let height: CGFloat

    @State private var offset = CGSize.zero
    @State private var opacity: Double = 0

    init(cardShown: Binding<Bool>,
         cardDismissal: Binding<Bool>,
         height: CGFloat,
         @ViewBuilder content: () -> Content) {
        _cardShown = cardShown
        _cardDismissal = cardDismissal
        self.height = height
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Dimmed
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.5))
            .opacity(opacity)
            .onTapGesture {
                dismiss()
            }

            // Card
            VStack {
                Spacer()

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 15)
                        .frame(width: UIScreen.main.bounds.width, height: height)
                        .foregroundColor(MailResourcesAsset.backgroundColor)
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(MailResourcesAsset.separatorColor)
                            .frame(width: 44, height: 4)
                        Spacer()
                    }
                    .padding(.top, 12)

                    content
                }
                .frame(height: height)
                .offset(self.offset)
                .gesture(DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.height > 0 {
                            self.offset.height = gesture.translation.height
                        }
                    }
                    .onEnded {
                        if $0.predictedEndLocation.y < height * 0.5 {
                            self.offset.height = 0
                        } else {
                            self.dismiss()
                        }
                    })
            }
        }
        .onChange(of: cardDismissal) { newValue in
            if !newValue {
                dismiss()
            }
        }
        .onAppear {
            present()
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func present() {
        offset.height = height
        withAnimation {
            self.offset.height = 0
            self.opacity = 1
        }
    }

    public func dismiss() {
        cardDismissal = false
        withAnimation {
            self.offset.height = height
            self.opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            cardShown.toggle()
        }
    }
}
