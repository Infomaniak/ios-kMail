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

import MailResources
import SwiftUI

struct Slide: Identifiable {
    var id: Int
    var backgroundImage: Image
    var illustrationImage: Image
    var title: String
    var description: String
}

@MainActor class OnboardingViewModel: ObservableObject {
    let slides = [
        Slide(id: 1,
              backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground1),
              illustrationImage: Image(resource: MailResourcesAsset.onboardingIllu1),
              title: MailResourcesStrings.Localizable.onBoardingTitle1,
              description: ""),
        Slide(id: 2,
              backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground2),
              illustrationImage: Image(resource: MailResourcesAsset.onboardingIllu2),
              title: MailResourcesStrings.Localizable.onBoardingTitle2,
              description: MailResourcesStrings.Localizable.onBoardingDescription2),
        Slide(id: 3,
              backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground3),
              illustrationImage: Image(resource: MailResourcesAsset.onboardingIllu3),
              title: MailResourcesStrings.Localizable.onBoardingTitle3,
              description: MailResourcesStrings.Localizable.onBoardingDescription3),
        Slide(id: 4,
              backgroundImage: Image(resource: MailResourcesAsset.onboardingBackground4),
              illustrationImage: Image(resource: MailResourcesAsset.onboardingIllu4),
              title: MailResourcesStrings.Localizable.onBoardingTitle4,
              description: MailResourcesStrings.Localizable.onBoardingDescription4)
    ]
}
