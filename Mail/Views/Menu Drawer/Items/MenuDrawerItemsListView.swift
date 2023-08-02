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

import InfomaniakBugTracker
import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import SwiftUI

struct MenuDrawerItemsAdvancedListView: View {
    @State private var isShowingRestoreMails = false

    @Environment(\.openURL) private var openURL

    let mailboxCanRestoreEmails: Bool

    var body: some View {
        MenuDrawerItemsListView(title: MailResourcesStrings.Localizable.menuDrawerAdvancedActions,
                                matomoName: "advancedActions") {
            MenuDrawerItemCell(icon: MailResourcesAsset.drawerDownload,
                               label: MailResourcesStrings.Localizable.buttonImportEmails,
                               matomoName: "importEmails") {
                openURL.callAsFunction(URLConstants.importMails.url)
            }
            if mailboxCanRestoreEmails {
                MenuDrawerItemCell(
                    icon: MailResourcesAsset.restoreArrow,
                    label: MailResourcesStrings.Localizable.buttonRestoreEmails,
                    matomoName: "restoreEmails"
                ) {
                    isShowingRestoreMails = true
                }
                .floatingPanel(isPresented: $isShowingRestoreMails) {
                    RestoreEmailsView()
                }
            }
        }
    }
}

struct MenuDrawerItemsHelpListView: View {
    @EnvironmentObject private var mailboxManager: MailboxManager

    @Environment(\.openURL) private var openURL

    @State private var isShowingHelp = false
    @State private var isShowingBugTracker = false

    @LazyInjectService private var accountManager: AccountManager

    var body: some View {
        MenuDrawerItemsListView {
            MenuDrawerItemCell(icon: MailResourcesAsset.feedback,
                               label: MailResourcesStrings.Localizable.buttonFeedback,
                               matomoName: "feedback") {
                sendFeedback()
            }
            MenuDrawerItemCell(icon: MailResourcesAsset.help,
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
    }

    private func sendFeedback() {
        if mailboxManager.account.user?.isStaff == true {
            isShowingBugTracker.toggle()
        } else if let userReportURL = URL(string: MailResourcesStrings.Localizable.urlUserReportiOS) {
            openURL.callAsFunction(userReportURL)
        }
    }
}

struct MenuDrawerItemsListView<Content: View>: View {
    var title: String?
    var matomoName: String?

    @ViewBuilder let content: () -> Content

    @State private var isExpanded = false

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
                    HStack(spacing: 12) {
                        ChevronIcon(style: isExpanded ? .up : .down, color: .secondary)
                        Text(title)
                            .textStyle(.bodySmallSecondary)
                        Spacer()
                    }
                }
                .padding(.vertical, UIConstants.menuDrawerVerticalPadding)
            }

            if title == nil || isExpanded {
                content()
            }
        }
        .padding(.horizontal, UIConstants.menuDrawerHorizontalPadding)
    }
}

struct ItemsListView_Previews: PreviewProvider {
    static var previews: some View {
        MenuDrawerItemsListView(title: "Actions avancées") {
            MenuDrawerItemCell(icon: MailResourcesAsset.drawerDownload,
                               label: "Importer des mails",
                               matomoName: "") { print("Hello") }
            MenuDrawerItemCell(icon: MailResourcesAsset.restoreArrow,
                               label: "Restaurer des mails",
                               matomoName: "") { print("Hello") }
        }
        .previewLayout(.sizeThatFits)
        .previewDevice(PreviewDevice(stringLiteral: "iPhone 11 Pro"))
    }
}
