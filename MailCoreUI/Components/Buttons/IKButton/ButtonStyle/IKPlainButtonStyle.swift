/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import MailCore
import MailResources
import SwiftUI

public struct IKPlainButtonStyle: ButtonStyle {
    @Environment(\.ikButtonLoading) private var isLoading: Bool

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.ikLabel)
            .modifier(IKButtonOpacityAnimationModifier(isPressed: configuration.isPressed))
            .modifier(IKButtonLoadingModifier(isPlain: true))
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonLayout())
            .modifier(IKButtonFilledModifier())
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
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
            }

            Section("Large Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
                .controlSize(.large)
            }

            Section("Full Width Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
                .controlSize(.large)
                .ikButtonFullWidth(true)
            }

            Section("Button With Different Colors") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain)
                    }
                }
                .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
                .ikButtonSecondaryStyle(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
            }

            Section("Loading Button") {
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
        .buttonStyle(.ikPlain)
        .navigationTitle("Plain Button")
    }
}
