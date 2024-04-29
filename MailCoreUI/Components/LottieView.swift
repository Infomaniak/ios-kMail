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
import MailResources
import SwiftUI
import UIKit

public extension LottieAnimationView {
    func updateColor(color: UIColor, darkColor: UIColor, for keyPath: AnimationKeypath) {
        let color = UITraitCollection.current.userInterfaceStyle == .dark ? darkColor : color
        let colorProvider = ColorValueProvider(color.lottieColorValue)
        setValueProvider(colorProvider, keypath: keyPath)
    }
}

public struct LottieConfiguration {
    public let id: Int
    public let filename: String
    public let loopMode: LottieLoopMode
    public let contentMode: UIView.ContentMode
    public let loopFrameStart: Int?
    public let loopFrameEnd: Int?

    public init(
        id: Int,
        filename: String,
        loopMode: LottieLoopMode = .playOnce,
        contentMode: UIView.ContentMode = UIView.ContentMode.scaleAspectFit,
        loopFrameStart: Int? = nil,
        loopFrameEnd: Int? = nil
    ) {
        self.id = id
        self.filename = filename
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.loopFrameStart = loopFrameStart
        self.loopFrameEnd = loopFrameEnd
    }
}

class LottieViewModel: ObservableObject {
    var colorScheme = UITraitCollection.current.userInterfaceStyle
    var accentColor = UserDefaults.shared.accentColor
}

public struct LottieView: UIViewRepresentable {
    public typealias UpdateColorsClosure = (LottieAnimationView, LottieConfiguration) -> Void

    @StateObject private var viewModel = LottieViewModel()

    let configuration: LottieConfiguration
    let isVisible: Bool
    let updateColors: UpdateColorsClosure?
    let completionFirstPlay: (() -> Void)?

    public init(
        configuration: LottieConfiguration,
        isVisible: Bool = true,
        updateColors: UpdateColorsClosure? = nil,
        completionFirstPlay: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self.isVisible = isVisible
        self.updateColors = updateColors
        self.completionFirstPlay = completionFirstPlay
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()

        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(configuration.filename, bundle: MailResourcesResources.bundle)
        animationView.animation = animation
        animationView.contentMode = configuration.contentMode
        animationView.loopMode = configuration.loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        resumePlaying(animationView: animationView)

        DispatchQueue.main.async {
            updateColors?(animationView, configuration)
        }

        return view
    }

    private func resumePlaying(animationView: LottieAnimationView) {
        animationView.play { _ in
            completionFirstPlay?()

            guard let loopFrameStart = configuration.loopFrameStart,
                  let loopFrameEnd = configuration.loopFrameEnd else { return }

            animationView.play(
                fromFrame: AnimationFrameTime(loopFrameStart),
                toFrame: AnimationFrameTime(loopFrameEnd),
                loopMode: .loop
            )
        }
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        guard isVisible, let animationView = uiView.subviews.first as? LottieAnimationView else { return }

        if !animationView.isAnimationPlaying {
            resumePlaying(animationView: animationView)
        }

        let newColorScheme = UITraitCollection.current.userInterfaceStyle
        let newAccentColor = UserDefaults.shared.accentColor
        guard viewModel.colorScheme != newColorScheme || viewModel.accentColor != newAccentColor
        else { return }

        viewModel.colorScheme = newColorScheme
        viewModel.accentColor = newAccentColor

        DispatchQueue.main.async {
            updateColors?(animationView, configuration)
        }
    }
}