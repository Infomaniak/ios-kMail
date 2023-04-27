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

import Combine
import MailResources
import SwiftUI
import SwiftUIBackports

extension View {
    func floatingPanel<Content: View>(isPresented: Binding<Bool>,
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: isPresented) {
            if #available(iOS 16.0, *) {
                content().modifier(SelfSizingPanelViewModifier())
            } else {
                content().modifier(SelfSizingPanelBackportViewModifier())
            }
        }
    }

    func floatingPanel<Item: Identifiable, Content: View>(item: Binding<Item?>,
                                                          @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        sheet(item: item) { item in
            if #available(iOS 16.0, *) {
                content(item).modifier(SelfSizingPanelViewModifier())
            } else {
                content(item).modifier(SelfSizingPanelBackportViewModifier())
            }
        }
    }

    func ikPresentationCornerRadius(_ cornerRadius: CGFloat?) -> some View {
        if #available(iOS 16.4, *) {
            return presentationCornerRadius(cornerRadius)
        } else {
            return introspectViewController { viewController in
                viewController.sheetPresentationController?.preferredCornerRadius = cornerRadius
            }
        }
    }
}

@available(iOS, introduced: 15, deprecated: 16, message: "Use native way")
struct SelfSizingPanelBackportViewModifier: ViewModifier {
    @State var currentDetents: Set<Backport.PresentationDetent> = [.medium]
    private let topPadding: CGFloat = 24

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.bottom, 16)
        }
        .padding(.top, topPadding)
        .introspectScrollView { scrollView in
            guard !currentDetents.contains(.large) else { return }
            let totalPanelContentHeight = scrollView.contentSize.height + topPadding

            scrollView.isScrollEnabled = totalPanelContentHeight > (scrollView.window?.bounds.height ?? 0)
            if totalPanelContentHeight > (scrollView.window?.bounds.height ?? 0) / 2 {
                currentDetents = [.medium, .large]
            }
        }
        .backport.presentationDragIndicator(.visible)
        .backport.presentationDetents(currentDetents)
        .ikPresentationCornerRadius(20)
    }
}

@available(iOS 16.0, *)
struct SelfSizingPanelViewModifier: ViewModifier {
    @State var currentDetents: Set<PresentationDetent> = [.height(0)]
    @State var selection: PresentationDetent = .height(0)
    private let topPadding: CGFloat = 24

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.bottom, 16)
        }
        .padding(.top, topPadding)
        .introspectScrollView { scrollView in
            let totalPanelContentHeight = scrollView.contentSize.height + topPadding
            guard selection != .height(totalPanelContentHeight) else { return }

            scrollView.isScrollEnabled = totalPanelContentHeight > (scrollView.window?.bounds.height ?? 0)
            DispatchQueue.main.async {
                currentDetents = [.height(0), .height(totalPanelContentHeight)]
                selection = .height(totalPanelContentHeight)

                // Hack to let time for the animation to finish, after animation is complete we can modify the state again
                // if we don't do this the animation is cut before finishing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentDetents = [selection]
                }
            }
        }
        .presentationDetents(currentDetents, selection: $selection)
        .presentationDragIndicator(.visible)
        .ikPresentationCornerRadius(20)
    }
}
