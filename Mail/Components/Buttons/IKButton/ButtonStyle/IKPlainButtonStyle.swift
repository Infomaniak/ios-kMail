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

struct IKPlainButtonStyle: ButtonStyle {
    var animation: IKButtonTapAnimation

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(IKButtonOpacityAnimationModifier(
                isAnimationEnabled: animation == .opacity,
                isPressed: configuration.isPressed
            ))
            .modifier(IKButtonLoadingModifier(isPlain: true))
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonLayout())
            .modifier(IKButtonFilledModifier())
            .modifier(IKButtonScaleAnimationModifier(isAnimationEnabled: animation == .scale, isPressed: configuration.isPressed))
    }
}

#Preview {
    NavigationView {
        List {
            Section("Standard Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
            }

            Section("Loading Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikButtonLoading(true)
            }

            Section("Large Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .controlSize(.large)
            }

            Section("Full Width Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .controlSize(.large)
                .ikButtonFullWidth(true)
            }

            Section("Button With Different Colors") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
                .ikButtonSecondaryStyle(MailResourcesAsset.backgroundSecondaryColor.swiftUIColor)
            }

            Section("Scale Animation") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikPlainButton(animation: .scale)
            }
        }
        .ikPlainButton()
        .navigationTitle("Plain Button")
    }
}
