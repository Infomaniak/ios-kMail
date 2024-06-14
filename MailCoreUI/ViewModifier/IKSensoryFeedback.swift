/*
 Infomaniak Mail - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

import SwiftUI

public enum IKSensoryFeedback {
    case impact(weight: IKSensoryFeedback.IKWeight = .medium, intensity: Double = 1.0)

    @available(iOS 17.0, macOS 14.0, *)
    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .impact(let ikWeight, let intensity):
            return .impact(weight: ikWeight.weight, intensity: intensity)
        }
    }

    func trigger() {
        switch self {
        case .impact(let ikWeight, let intensity):
            let feedback = UIImpactFeedbackGenerator(style: ikWeight.feedbackStyle)
            feedback.impactOccurred(intensity: CGFloat(intensity))
        }
    }
}

public extension IKSensoryFeedback {
    enum IKWeight {
        case heavy, medium, light

        @available(iOS 17.0, macOS 14.0, *)
        var weight: SensoryFeedback.Weight {
            switch self {
            case .heavy:
                return .heavy
            case .medium:
                return .medium
            case .light:
                return .light
            }
        }

        var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .heavy:
                return .heavy
            case .medium:
                return .medium
            case .light:
                return .light
            }
        }
    }
}

public struct IKSensoryFeedbackModifier<T: Equatable>: ViewModifier {
    let feedback: IKSensoryFeedback
    let trigger: T

    public func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _ in
                feedback.trigger()
            }
    }
}

@available(iOS, obsoleted: 17.0, message: "SwiftUI.View.sensoryFeedback is available on iOS 17.")
@available(macOS, obsoleted: 14.0, message: "SwiftUI.View.sensoryFeedback is available on macOS 14.")
public extension View {
    /// Plays the specified `feedback` when the provided `trigger` value
    /// changes.
    ///
    /// Backport of `SwiftUI.View.SensoryFeedback`
    @ViewBuilder func ikSensoryFeedback<T: Equatable>(_ feedback: IKSensoryFeedback, trigger: T) -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            sensoryFeedback(feedback.sensoryFeedback, trigger: trigger)
        } else {
            modifier(IKSensoryFeedbackModifier(feedback: feedback, trigger: trigger))
        }
    }
}
