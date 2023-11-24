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

struct IKLinkButtonStyle: ButtonStyle {
    @Environment(\.ikButtonPrimaryStyle) private var ikButtonPrimaryStyle: any ShapeStyle

    @Environment(\.controlSize) private var controlSize
    @Environment(\.isEnabled) private var isEnabled

    var animation: IKButtonTapAnimation
    var isInlined = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AnyShapeStyle(foreground(role: configuration.role)))
            .modifier(IKButtonLoadingModifier(isPlain: false))
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonLayout(isInlined: isInlined))
            .contentShape(Rectangle())
            .modifier(IKButtonOpacityAnimationModifier(
                isAnimationEnabled: animation == .opacity,
                isPressed: configuration.isPressed
            ))
            .modifier(IKButtonScaleAnimationModifier(isAnimationEnabled: animation == .scale, isPressed: configuration.isPressed))
    }

    private func foreground(role: ButtonRole?) -> any ShapeStyle {
        if !isEnabled {
            return MailTextStyle.bodyMediumOnDisabled.color
        } else if role == .destructive {
            return MailTextStyle.bodyMediumError.color
        } else {
            return ikButtonPrimaryStyle
        }
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

            Section("Destructive Button") {
                Button(role: .destructive) {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
            }

            Section("Small Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .controlSize(.small)
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

            Section("Button With Different Color") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
            }

            Section("Scale Animation") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikLinkButton(animation: .scale)
            }

            Section("Inlined Button") {
                Button {
                    /* Preview */
                } label: {
                    IKButtonLabel(title: "Lorem Ipsum", icon: MailResourcesAsset.pencilPlain)
                }
                .ikLinkButton(isInlined: true)
            }
        }
        .ikLinkButton()
        .navigationTitle("Link Button")
    }
}
