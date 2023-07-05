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

import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import Social
import SwiftUI
import UIKit

// <core> most definitely

/// Represents `any` (ie. all of them not the type) curried closure, of arbitrary type.
typealias CurriedClosure<Input, Output> = (Input) -> Output

/// A closure that take no argument and return nothing, but technically curried.
typealias SimpleClosure = CurriedClosure<Void, Void>

/// Append a SimpleClosure closure to another one
func + (_ lhs: @escaping SimpleClosure, _ rhs: @escaping SimpleClosure) -> SimpleClosure {
    let closure: SimpleClosure = { _ in
        lhs(())
        rhs(())
    }
    return closure
}

// </core>

struct ComposeMessageWrapperView: View {
    private var itemProviders: [NSItemProvider]
    private var dismissHandler: SimpleClosure

    @State private var draft: Draft

    @LazyInjectService private var accountManager: AccountManager

    init(dismissHandler: @escaping SimpleClosure, itemProviders: [NSItemProvider], draft: Draft = Draft()) {
        _draft = State(initialValue: draft)

        // Append save draft action if possible
        @InjectService var accountManager: AccountManager
        if let mailboxManager = accountManager.currentMailboxManager {
            let saveDraft: SimpleClosure = { _ in
                let detached = draft.detached()
                Task {
                    @InjectService var draftManager: DraftManager
                    _ = await draftManager.initialSaveRemotely(draft: detached, mailboxManager: mailboxManager)
                }
            }
            self.dismissHandler = saveDraft + dismissHandler
        } else {
            self.dismissHandler = dismissHandler
        }

        self.itemProviders = itemProviders
    }

    var body: some View {
        if let mailboxManager = accountManager.currentMailboxManager {
            ComposeMessageView.newMessage(draft, mailboxManager: mailboxManager, itemProviders: itemProviders)
                .environmentObject(mailboxManager)
                .environment(\.dismissModal) {
                    self.dismissHandler(())
                }
        } else {
            PleaseLoginView(tapHandler: dismissHandler)
        }
    }
}

struct PleaseLoginView: View {
    @State var slide = Slide.onBoardingSlides.first!

    var tapHandler: SimpleClosure

    var body: some View {
        VStack {
            MailShareExtensionAsset.logoText.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(height: UIConstants.onboardingLogoHeight)
                .padding(.top, UIConstants.onboardingLogoPaddingTop)
            // TODO: i18n
            Text("Please login in ikMail first")
                .textStyle(.header2)
                .padding(.top, UIConstants.onboardingLogoPaddingTop)
            LottieView(configuration: slide.lottieConfiguration!)
            Spacer()
        }.onTapGesture {
            tapHandler(())
        }
    }
}
