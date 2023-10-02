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

struct SyncInstallProfileTutorialView: View {
    @Environment(\.dismissModal) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var userCameBackFromSettings = false

    private let steps = [
        "Dans vos réglages, ouvrez l’onglet “Profil téléchargé” puis cliquer sur installer.",
        "Saisissez le code : renseigner le **code PIN** de votre téléphone",
        "Cliquer sur **Installer**.",
        "Coller le mot de passe de validation de l’étape précédente.",
        "Revenir sur votre application Mail."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: UIPadding.regular) {
                Text("!Installer le profil")
                    .textStyle(.header2)
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: UIPadding.regular) {
                    ForEach(steps.indices, id: \.self) { index in
                        if let stepMarkdown = try? AttributedString(markdown: "\(index + 1)\\. \(steps[index])") {
                            Text(stepMarkdown)
                        }
                        if index == 0 {
                            TipView(
                                message: "Tapez “Profil téléchargé” dans la recherche de vos réglages pour trouver facilement l’onglet !"
                            )
                        }
                    }
                }
                .textStyle(.bodySecondary)

                Spacer(minLength: 16)
                DeviceFrameView()
                Spacer()
            }
            .padding(value: .medium)
        }
        .padding(.bottom, value: .verySmall)
        .toolbar {
            ToolbarItem(placement: .principal) {
                SyncStepToolbarItem(step: 3, totalSteps: 3)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                MailButton(label: "!Accéder aux réglages") {
                    openURL(URL(string: "App-prefs:")!)
                }
                .mailButtonFullWidth(true)
                if userCameBackFromSettings {
                    MailButton(label: "!J'ai terminé") {
                        dismiss()
                    }
                    .mailButtonFullWidth(true)
                    .mailButtonStyle(.link)
                }
            }
            .padding(.horizontal, value: .medium)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                withAnimation {
                    userCameBackFromSettings = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SyncInstallProfileTutorialView()
    }
    .navigationViewStyle(.stack)
}
