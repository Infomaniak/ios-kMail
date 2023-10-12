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

import Foundation
import StoreKit
import SwiftUI

public enum ReviewType: String {
    case none
    case feedback
    case readyForReview
}

public class ReviewManager: ObservableObject {
    public init() {}

    public func shouldRequestReview() -> Bool {
        switch UserDefaults.shared.appReview {
        case .none, .feedback:
            let request = UserDefaults.shared.openingUntilReview <= 0
            if request {
                UserDefaults.shared.openingUntilReview = Constants.openingBeforeReview
                return true
            }
            return false
        case .readyForReview:
            if UserDefaults.shared.openingUntilReview <= 0 {
                UserDefaults.shared.openingUntilReview = Constants.openingBeforeReview
                requestReview()
            }
            return false
        }
    }

    public func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
