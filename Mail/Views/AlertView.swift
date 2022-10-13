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

struct AlertView<Content>: View where Content: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            content
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(MailResourcesAsset.backgroundColor.swiftUiColor)
                .cornerRadius(16)
                .padding(16)
        }
    }
}

struct CustomAlertModifier<AlertContent>: ViewModifier where AlertContent: View {
    @Binding var isPresented: Bool
    let alertView: AlertContent

    func body(content: Content) -> some View {
        content
            .overlay {
                Group {
                    if isPresented {
                        AlertView {
                            alertView
                        }
                    }
                }
                .animation(.default, value: isPresented)
            }
    }
}

extension View {
    func customAlert<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        modifier(CustomAlertModifier(isPresented: isPresented, alertView: content()))
    }
}

struct AlertView_Previews: PreviewProvider {
    static var previews: some View {
        AlertView {
            CreateFolderView(mailboxManager: PreviewHelper.sampleMailboxManager,
                             state: GlobalAlert(),
                             mode: .create)
        }
    }
}
