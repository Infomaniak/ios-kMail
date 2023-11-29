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

struct IKFloatingAppButtonStyle: ButtonStyle {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.ikButtonLoading) private var isLoading: Bool

    let isExtended: Bool

    private var size: CGFloat {
        if controlSize == .large {
            return UIConstants.buttonExtraLargeHeight
        } else {
            return UIConstants.buttonLargeHeight
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.ikLabel)
            .modifier(IKButtonLoadingModifier(isPlain: true))
            .font(MailTextStyle.bodyMedium.font)
            .padding(.horizontal, UIPadding.regular)
            .frame(width: isExtended ? nil : size, height: size)
            .modifier(IKButtonFilledModifier())
            .modifier(IKButtonScaleAnimationModifier(isPressed: configuration.isPressed))
            .allowsHitTesting(!isLoading)
    }
}

#Preview {
    NavigationView {
        List {
            Section("Standard Button") {
                Button {
                    /* Preview */
                } label: {
                    IKIcon(MailResourcesAsset.pencilPlain)
                }
                .buttonStyle(.ikFloatingAppButton(isExtended: false))
            }

            Section("Extended Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
            }

            Section("Large FAB") {
                Button {
                    /* Preview */
                } label: {
                    IKIcon(MailResourcesAsset.pencilPlain)
                }
                .buttonStyle(.ikFloatingAppButton(isExtended: false))
                .controlSize(.large)
            }

            Section("Loading Button") {
                Button {
                    /* Preview */
                } label: {
                    IKIcon(MailResourcesAsset.pencilPlain)
                }
                .buttonStyle(.ikFloatingAppButton(isExtended: false))
                .ikButtonLoading(true)
            }

            Section("Loading Extended Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
                .ikButtonLoading(true)
            }

            Section("Disabled Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
                .disabled(true)
            }
        }
        .navigationTitle("Floating Action Button")
        .buttonStyle(.ikFloatingAppButton(isExtended: true))
    }
}
