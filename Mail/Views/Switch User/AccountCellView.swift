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

import ContactCard
import DesignSystem
import InfomaniakCore
import InfomaniakCoreCommonUI
import InfomaniakDI
import InfomaniakLogin
import MailCore
import MailCoreUI
import MailResources
import RealmSwift
import SwiftModalPresentation
import SwiftUI

struct AccountCellPlaceholderView: View {
    var body: some View {
        Button { /* Placeholder does nothing */ } label: {
            HStack {
                Circle()
                    .fill(MailResourcesAsset.grayActionColor.swiftUIColor)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text("user.displayName")
                        .redacted(reason: .placeholder)
                        .textStyle(.bodyMedium)
                    Text("user.email")
                        .redacted(reason: .placeholder)
                        .textStyle(.bodySecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, value: .mini)
        }
    }
}

struct AccountCellView: View {
    @Environment(\.dismissModal) private var dismissModal

    @Binding var selectedUserId: Int?

    let mailboxManager: MailboxManager?
    let user: InfomaniakCore.UserProfile

    private var isSelected: Bool {
        return selectedUserId == user.id
    }

    var body: some View {
        Button {
            guard !isSelected else { return }

            @InjectService var matomo: MatomoUtils
            @InjectService var accountManager: AccountManager

            matomo.track(eventWithCategory: .account, name: "switch")
            dismissModal()
            accountManager.switchAccount(newUserId: user.id)
        } label: {
            AccountHeaderCell(user: user, mailboxManager: mailboxManager, isSelected: Binding(get: {
                isSelected
            }, set: {
                selectedUserId = $0 ? user.id : nil
            }))
        }
    }
}

struct AccountHeaderCell: View {
    let user: InfomaniakCore.UserProfile

    @ModalState private var isShowingContactCard = false

    /// Optional as this view can be displayed from a context without a mailboxManager available
    let mailboxManager: MailboxManager?

    @Binding var isSelected: Bool

    @Environment(\.colorScheme) private var colorScheme

    enum AccountHeaderCellType {
        case switchAccount, selectComposeMailbox
    }

    var type = AccountHeaderCellType.switchAccount

    var body: some View {
        HStack {
            AvatarView(mailboxManager: mailboxManager, contactConfiguration: .user(user: user), size: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(user.displayName)
                    .textStyle(.bodyMedium)
                Text(user.email)
                    .textStyle(.bodySecondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            switch type {
            case .switchAccount:
                if isSelected {
                    contactCardButton
                        .sheet(isPresented: $isShowingContactCard) {
                            contactCardContent
                        }
                }

            case .selectComposeMailbox:
                ChevronIcon(direction: .down)
            }
        }
        .padding(.vertical, value: .mini)
    }

    @State private var hasFlipped = false

    private var contactCardButton: some View {
        let baseColor = UserDefaults.shared.accentColor
        return Button {
            isShowingContactCard = true
        } label: {
            MailResourcesAsset.qrCode.swiftUIImage
                .iconSize(.medium)
                .scaleEffect(x: hasFlipped ? -1 : 1, y: 1)
                .foregroundStyle(.tint)
                .padding(IKPadding.mini)
                .background(
                    RoundedRectangle(cornerRadius: IKRadius.medium)
                        .foregroundStyle(baseColor.primary.swiftUIColor.opacity(0.1))
                )
                .onAppear {
                    withAnimation(.default.delay(0.25)) {
                        hasFlipped.toggle()
                    }
                }
        }
    }

    @ViewBuilder
    private var contactCardContent: some View {
        if #available(iOS 16.4, *) {
            let baseUserAccentColor = UserDefaults.shared.accentColor
            let onBoardingImageByTheme = onBoardingImageByTheme()

            let myTheme = ContactCardTheme(
                primary: baseUserAccentColor.primary.swiftUIColor,
                secondary: baseUserAccentColor.secondary.swiftUIColor,
                primaryText: MailResourcesAsset.textPrimaryColor.swiftUIColor,
                secondaryText: MailResourcesAsset.textSecondaryColor.swiftUIColor,
                onAccent: baseUserAccentColor.onAccent.swiftUIColor,
                background: MailResourcesAsset.backgroundColor.swiftUIColor,
                backgroundTint: MailResourcesAsset.backgroundTertiaryColor.swiftUIColor,
                navBarBackground: baseUserAccentColor.navBarBackground.swiftUIColor,
                snackbarActionColor: baseUserAccentColor.snackbarActionColor.swiftUIColor,
                onboardingImage: onBoardingImageByTheme
            )
            ContactCardView(
                userProfile: user,
                rootPath: FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: MailAppTargetAssembly.sharedAppGroupName
                ) ?? URL.temporaryDirectory
            )
            .id(UserDefaults.shared.accentColor)
            .environment(\.contactCardTheme, myTheme)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private func isEffectiveDarkMode() -> Bool {
        switch UserDefaults.shared.theme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return colorScheme == .dark
        }
    }

    private func onBoardingImageByTheme() -> Image {
        let isDark = isEffectiveDarkMode()
        let isBlue = UserDefaults.shared.accentColor == .blue

        var asset: MailResourcesImages
        switch (isDark, isBlue) {
        case (true, true):
            asset = MailResourcesAsset.contactCardBleuDark
        case (true, false):
            asset = MailResourcesAsset.contactCardPinkDark
        case (false, true):
            asset = MailResourcesAsset.contactCardBleu
        case (false, false):
            asset = MailResourcesAsset.contactCardPink
        }

        return asset.swiftUIImage
    }
}

#Preview {
    AccountCellView(
        selectedUserId: .constant(nil),
        mailboxManager: nil,
        user: PreviewHelper.sampleUser
    )
}
