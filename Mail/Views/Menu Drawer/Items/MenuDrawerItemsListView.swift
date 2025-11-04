/*
 Infomaniak Mail - iOS App
 Copyright (C) 2024 Infomaniak Network SA

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
import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakCoreSwiftUI
import InfomaniakCoreUIResources
import InfomaniakDI
import MailCore
import MailCoreUI
import MailResources
import SwiftModalPresentation
import SwiftUI

struct MenuDrawerItemsAdvancedListView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    @InjectService private var platformDetector: PlatformDetectable

    @Environment(\.openURL) private var openURL

    @ModalState private var isShowingRestoreMails = false

    let mailboxCanRestoreEmails: Bool

    var body: some View {
        MenuDrawerItemsListView(title: MailResourcesStrings.Localizable.menuDrawerAdvancedActions,
                                matomoName: "advancedActions") {
            if !platformDetector.isMac {
                MenuDrawerItemCell(icon: MailResourcesAsset.doubleArrowsSynchronize,
                                   label: MailResourcesStrings.Localizable.syncCalendarsAndContactsTitle,
                                   matomoName: "syncProfile") {
                    @InjectService var matomo: MatomoUtils
                    matomo.track(eventWithCategory: .syncAutoConfig, name: "openFromMenuDrawer")
                    mainViewState.isShowingSyncProfile = true
                }
            }

            MenuDrawerItemCell(icon: MailResourcesAsset.drawerDownload,
                               label: MailResourcesStrings.Localizable.buttonImportEmails,
                               matomoName: "importEmails") {
                openURL(URLConstants.importMails.url)
            }

            if mailboxCanRestoreEmails {
                MenuDrawerItemCell(
                    icon: MailResourcesAsset.restoreArrow,
                    label: MailResourcesStrings.Localizable.buttonRestoreEmails,
                    matomoName: "restoreEmails"
                ) {
                    isShowingRestoreMails = true
                }
                .sheetOrAlertPanel(isPresented: $isShowingRestoreMails) {
                    RestoreEmailsView()
                }
            }
        }
    }
}

struct MenuDrawerItemsHelpListView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.currentUser) private var currentUser

    @ModalState private var isShowingHelp = false
    @ModalState private var isShowingBugTracker = false
    @ModalState private var isShowingUpdateVersionAlert = false

    var body: some View {
        MenuDrawerItemsListView {
            MenuDrawerItemCell(icon: MailResourcesAsset.feedback,
                               label: MailResourcesStrings.Localizable.buttonFeedback,
                               matomoName: "feedback") {
                if Constants.isUsingABreakableOSVersion {
                    isShowingUpdateVersionAlert = true
                } else {
                    sendFeedback()
                }
            }
            if !Bundle.main.isRunningInTestFlight {
                MenuDrawerItemCell(icon: MailResourcesAsset.laboratoryFlask,
                                   label: CoreUILocalizable.joinTheBetaButton,
                                   matomoName: "joinBetaProgram") {
                    openURL(URLConstants.testFlight.url)
                }
            }
            MenuDrawerItemCell(icon: MailResourcesAsset.circleQuestionmark,
                               label: MailResourcesStrings.Localizable.buttonHelp,
                               matomoName: "help") {
                isShowingHelp = true
            }
        }
        .sheet(isPresented: $isShowingHelp) {
            HelpView()
                .sheetViewStyle()
        }
        .sheet(isPresented: $isShowingBugTracker) {
            BugTrackerView(isPresented: $isShowingBugTracker)
        }
        .mailCustomAlert(isPresented: $isShowingUpdateVersionAlert) {
            UpdateVersionAlertView(onLaterPressed: sendFeedback)
        }
    }

    private func sendFeedback() {
        if currentUser.value.isStaff == true {
            isShowingBugTracker.toggle()
        } else if let userReportURL = URL(string: MailResourcesStrings.Localizable.urlUserReportiOS) {
            openURL(userReportURL)
        }
    }
}

struct MenuDrawerItemsListView<Content: View>: View {
    @State private var isExpanded = false

    var title: String?
    var matomoName: String?

    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                        if let matomoName {
                            @InjectService var matomo: MatomoUtils
                            matomo.track(eventWithCategory: .menuDrawer, name: matomoName, value: isExpanded)
                        }
                    }
                } label: {
                    HStack(spacing: IKPadding.menuDrawerCellChevronSpacing) {
                        ChevronIcon(direction: isExpanded ? .up : .down)
                        Text(title)
                            .textStyle(.bodySmallSecondary)
                        Spacer()
                    }
                    .padding(value: .medium)
                }
            }

            if title == nil || isExpanded {
                content()
            }
        }
    }
}

#Preview {
    MenuDrawerItemsListView(title: "Actions avancées") {
        MenuDrawerItemCell(icon: MailResourcesAsset.drawerDownload,
                           label: "Importer des mails",
                           matomoName: "") { print("Hello") }
        MenuDrawerItemCell(icon: MailResourcesAsset.restoreArrow,
                           label: "Restaurer des mails",
                           matomoName: "") { print("Hello") }
    }
}
