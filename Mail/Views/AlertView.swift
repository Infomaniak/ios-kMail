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

import MailCore
import MailResources
import SwiftUI

struct AlertView<Content>: View where Content: View {
    @State private var isShowing = false

    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            content
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(MailResourcesAsset.backgroundTertiaryColor.swiftUIColor)
                .cornerRadius(16)
                .frame(maxWidth: UIConstants.componentsMaxWidth)
                .padding(16)
        }
        .opacity(isShowing ? 1 : 0)
        .background(ClearFullScreenView())
        .onAppear {
            // Re-enable animations after the ViewController is presented
            UIView.setAnimationsEnabled(true)
            withAnimation(.easeInOut(duration: 0.25)) {
                isShowing = true
            }
        }
        .onDisappear {
            // Re-enable animations after the ViewController is dismissed
            UIView.setAnimationsEnabled(true)
        }
    }
}

struct CustomAlertModifier<AlertContent>: ViewModifier where AlertContent: View {
    @Binding var isPresented: Bool
    let alertView: AlertContent

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                AlertView {
                    alertView
                }
            }
            .onChange(of: isPresented) { _ in
                // Disable the default slide over animation when presenting / dismissing the ViewController
                UIView.setAnimationsEnabled(false)
            }
    }
}

struct CustomAlertItemModifier<Item, AlertContent>: ViewModifier where Item: Identifiable, AlertContent: View {
    @Binding var item: Item?
    let alertView: (Item) -> AlertContent

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: $item) { item in
                AlertView {
                    alertView(item)
                }
            }
            .onChange(of: item?.id) { _ in
                UIView.setAnimationsEnabled(false)
            }
    }
}

private struct ClearFullScreenView: UIViewRepresentable {
    private static let maxSearchDepth = 5
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            clearBackgroundSuperviews(view: self)
        }

        private func clearBackgroundSuperviews(view: UIView, level: Int = 0) {
            guard level < maxSearchDepth else { return }

            if let superview = view.superview {
                superview.backgroundColor = .clear
                clearBackgroundSuperviews(view: superview, level: level + 1)
            }
        }
    }

    func makeUIView(context: Context) -> UIView {
        return BackgroundRemovalView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func customAlert<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        modifier(CustomAlertModifier(isPresented: isPresented, alertView: content()))
    }

    func customAlert<Item, Content>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View
        where Item: Identifiable, Content: View {
        modifier(CustomAlertItemModifier(item: item, alertView: content))
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView {
            CreateFolderView(mode: .create)
        }
        .environmentObject(PreviewHelper.sampleMailboxManager)
    }
}
