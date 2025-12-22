/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

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

import Lottie
import MailCore
import MailResources
import SwiftUI

struct EasterEggViewModifier: ViewModifier {
    @Binding var presentedEasterEgg: EasterEgg?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let showingEasterEgg = presentedEasterEgg {
                    LottieView(animation: .named(showingEasterEgg.lottieName, bundle: MailResourcesResources.bundle))
                        .animationDidFinish { _ in
                            presentedEasterEgg = nil
                        }
                        .playing(loopMode: .playOnce)
                        .frame(maxWidth: .infinity)
                        .scaledToFit()
                        .padding(.bottom, 96)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .onAppear {
                            showingEasterEgg.onTrigger()
                        }
                }
            }
    }
}

extension View {
    func easterEggOverlay(_ presentedEasterEgg: Binding<EasterEgg?>) -> some View {
        modifier(EasterEggViewModifier(presentedEasterEgg: presentedEasterEgg))
    }
}
