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

import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct AskForReviewView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    @LazyInjectService private var matomo: MatomoUtils
    @LazyInjectService private var reviewManager: ReviewManageable

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(MailResourcesStrings.Localizable.reviewAlertTitle)
                .textStyle(.bodyMedium)
                .padding(.bottom, IKPadding.alertTitleBottom)

            ModalButtonsView(
                primaryButtonTitle: MailResourcesStrings.Localizable.buttonYes,
                secondaryButtonTitle: MailResourcesStrings.Localizable.buttonNo
            ) {
                matomo.track(eventWithCategory: .appReview, name: "like")
                UserDefaults.shared.appReview = .readyForReview
                reviewManager.requestReview()
            } secondaryButtonAction: {
                matomo.track(eventWithCategory: .appReview, name: "dislike")
                // Ask for feedback
                if let userReportURL = URL(string: MailResourcesStrings.Localizable.urlUserReportiOS) {
                    UserDefaults.shared.appReview = .feedback
                    mainViewState.isShowingSafariView = IdentifiableURL(url: userReportURL)
                }
            }
        }
        .onAppear {
            matomo.track(eventWithCategory: .appReview, action: .data, name: "alertPresented")
        }
    }
}

#Preview {
    AskForReviewView()
}
