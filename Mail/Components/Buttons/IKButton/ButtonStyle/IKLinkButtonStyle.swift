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
    @Environment(\.ikButtonLoading) private var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled

    var isInlined = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.ikLabel)
            .foregroundStyle(AnyShapeStyle(foreground(role: configuration.role)))
            .modifier(IKButtonLoadingModifier(isPlain: false))
            .modifier(IKButtonControlSizeModifier())
            .modifier(IKButtonExpandableModifier())
            .modifier(IKButtonLayout(isInlined: isInlined))
            .contentShape(Rectangle())
            .modifier(IKButtonOpacityAnimationModifier(isPressed: configuration.isPressed))
            .allowsHitTesting(!isLoading)
    }

    private func foreground(role: ButtonRole?) -> any ShapeStyle {
        if !isEnabled || isLoading {
            return MailResourcesAsset.textTertiaryColor.swiftUIColor
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
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
            }

            Section("Destructive Button") {
                Button(role: .destructive) {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
            }

            Section("Small Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .controlSize(.small)
            }

            Section("Full Width Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .controlSize(.large)
                .ikButtonFullWidth(true)
            }

            Section("Button With Different Color") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .ikButtonPrimaryStyle(MailResourcesAsset.aiColor.swiftUIColor)
            }

            Section("Inlined Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .buttonStyle(.ikLink(isInlined: true))
            }

            Section("Loading Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .ikButtonLoading(true)
            }

            Section("Disabled Button") {
                Button {
                    /* Preview */
                } label: {
                    Label { Text("Lorem Ipsum") } icon: {
                        IKIcon(MailResourcesAsset.pencilPlain, size: .medium)
                    }
                }
                .disabled(true)
            }
        }
        .buttonStyle(.ikLink())
        .navigationTitle("Link Button")
    }
}
