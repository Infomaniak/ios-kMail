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

extension LottieAnimationView {
    func updateColor(color: UIColor, darkColor: UIColor, for keyPath: AnimationKeypath) {
        let color = UITraitCollection.current.userInterfaceStyle == .dark ? darkColor : color
        let colorProvider = ColorValueProvider(color.lottieColorValue)
        setValueProvider(colorProvider, keypath: keyPath)
    }
}

struct LottieConfiguration {
    let id: Int
    let loopMode: LottieLoopMode
    let loopFrameStart: Int?
    let loopFrameEnd: Int?
}

class LottieViewModel: ObservableObject {
    var colorScheme = UITraitCollection.current.userInterfaceStyle
    var accentColor = UserDefaults.shared.accentColor
}

struct LottieView: UIViewRepresentable {
    @StateObject private var viewModel = LottieViewModel()

    let filename: String
    let configuration: LottieConfiguration

    let updateColors: ((LottieAnimationView, LottieConfiguration) -> Void)?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(filename)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = configuration.loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        animationView.play { _ in
            guard let loopFrameStart = configuration.loopFrameStart,
                  let loopFrameEnd = configuration.loopFrameEnd else { return }

            animationView.play(
                fromFrame: AnimationFrameTime(loopFrameStart),
                toFrame: AnimationFrameTime(loopFrameEnd),
                loopMode: .loop
            )
        }

        DispatchQueue.main.async {
            updateColors?(animationView, configuration)
        }

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }

        let newColorScheme = UITraitCollection.current.userInterfaceStyle
        let newAccentColor = UserDefaults.shared.accentColor
        guard viewModel.colorScheme != newColorScheme || viewModel.accentColor != newAccentColor else { return }

        viewModel.colorScheme = newColorScheme
        viewModel.accentColor = newAccentColor

        DispatchQueue.main.async {
            updateColors?(animationView, configuration)
        }
    }
}
