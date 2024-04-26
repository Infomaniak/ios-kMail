/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct UpdateVersionView: View {
    @State private var isShowingUpdateAlert = false
//    @Binding var isShowingUpdateVersionView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIPadding.small) {
            VStack(alignment: .leading, spacing: UIPadding.small) {
                HStack(alignment: .center, spacing: UIPadding.small) {
                    IKIcon(MailResourcesAsset.warning)
                        .foregroundStyle(MailResourcesAsset.orangeColor)
                    Text("Vos e-mails peuvent ne pas s’afficher correctement.")
                        .textStyle(.bodySmall)
                }

                Button {
                    //  matomo.track(eventWithCategory: .threadList, name: "")
                    isShowingUpdateAlert = true

                } label: {
                    HStack(spacing: UIPadding.small) {
                        Text("En savoir plus")
                            .textStyle(.bodySmallAccent)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.top, value: .regular)
            .padding(.bottom, value: .small)
            .padding(.horizontal, value: .regular)

            IKDivider(type: .full)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .customAlert(isPresented: $isShowingUpdateAlert) {
            UpdateVersionAlertView()
        }
    }
}

#Preview {
    UpdateVersionView()
}
