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

import Lottie
import SwiftUI

struct LottieConfiguration {
    let loopFrameStart: Int
    let loopFrameEnd: Int
}

struct LottieView: UIViewRepresentable {
    private let animationView = LottieAnimationView()

    let filename: String
    let configuration: LottieConfiguration

    func makeUIView(context: Context) -> some UIView {
        let view = UIView()

        let animation = LottieAnimation.named(filename)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.play { _ in
            animationView.play(
                fromFrame: AnimationFrameTime(configuration.loopFrameStart),
                toFrame: AnimationFrameTime(configuration.loopFrameEnd),
                loopMode: .loop
            )
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        // Update theme colors here
    }
}
