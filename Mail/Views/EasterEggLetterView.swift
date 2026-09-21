/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

import DesignSystem
import InfomaniakCoreCommonUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

/// Easter egg screen presented when tapping several times in a row on the send button.
/// It shows an open envelope with the letter sliding out of it.
struct EasterEggLetterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor

    @State private var isShowing = false
    @State private var isFlapOpen = false
    @State private var isLetterOut = false
    @State private var isLetterFloating = false

    // MARK: - View

    var body: some View {
        ZStack(alignment: .top) {
            MailResourcesAsset.backgroundColor.swiftUIColor
                .ignoresSafeArea()

            HStack {
                Spacer()
                CloseButton { dismiss() }
                    .padding(.trailing, value: .medium)
                    .padding(.top, value: .small)
            }

            OpenEnvelopeIllustration(
                accentColor: accentColor,
                isFlapOpen: isFlapOpen,
                isLetterOut: isLetterOut,
                isLetterFloating: isLetterFloating
            )
            .scaleEffect(isShowing ? 1 : 0.85)
            .opacity(isShowing ? 1 : 0)
            .accessibilityHidden(true)
        }
        .onTapGesture(perform: dismiss.callAsFunction)
        .matomoView(view: ["EasterEggLetterView"])
        .onAppear(perform: playAppearAnimation)
    }

    // MARK: - Func

    private func playAppearAnimation() {
        guard !reduceMotion else {
            isShowing = true
            isFlapOpen = true
            isLetterOut = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isShowing = true
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.3)) {
            isFlapOpen = true
        }
        withAnimation(.spring(response: 0.9, dampingFraction: 0.6).delay(0.6)) {
            isLetterOut = true
        }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(1.8)) {
            isLetterFloating = true
        }
    }
}

// MARK: - Illustration

/// An open envelope with a letter sliding out of it, drawn on a fixed 300x340 canvas.
private struct OpenEnvelopeIllustration: View {
    let accentColor: AccentColor
    let isFlapOpen: Bool
    let isLetterOut: Bool
    let isLetterFloating: Bool

    // MARK: Geometry

    private static let canvasSize = CGSize(width: 300, height: 340)
    private static let envelopeSize = CGSize(width: 260, height: 168)
    private static let letterSize = CGSize(width: 204, height: 240)
    /// Height of the flap unfolding above the envelope
    private static let flapHeight: CGFloat = 92
    /// Depth of the "V" shaped opening at the top of the envelope pocket
    private static let pocketNotchDepth: CGFloat = 38
    /// Distance between the canvas center and the envelope center
    private static let envelopeDrop: CGFloat = 30
    /// How much of the letter peeks out of the envelope
    private static let letterPeekHeight: CGFloat = 80
    /// Gap between the pocket notch apex and the top of the letter when it is fully hidden inside the envelope
    private static let hiddenLetterGap: CGFloat = 6
    /// Amplitude of the gentle floating animation applied to the letter
    private static let floatAmplitude: CGFloat = 10

    private static let lineFractions: [CGFloat] = [0.95, 1, 0.85, 1, 0.35]
    private static let textContentWidth = letterSize.width - 2 * IKPadding.medium

    private static var flapOffset: CGFloat {
        envelopeDrop - envelopeSize.height / 2 - flapHeight / 2
    }

    private static var letterOutOffset: CGFloat {
        envelopeDrop - envelopeSize.height / 2 - letterPeekHeight + letterSize.height / 2
    }

    private static var letterHiddenOffset: CGFloat {
        envelopeDrop - envelopeSize.height / 2 + pocketNotchDepth + hiddenLetterGap + letterSize.height / 2
    }

    private static var maskHeight: CGFloat {
        canvasSize.height / 2 + envelopeDrop + envelopeSize.height / 2
    }

    private static var shadowOffset: CGFloat {
        envelopeDrop + envelopeSize.height / 2 + 14
    }

    // MARK: - View

    var body: some View {
        ZStack {
            shadow
            flap
            envelopeBack
            letterLayer
            pocket
            pocketCreases
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
    }

    private var shadow: some View {
        Ellipse()
            .fill(Color.black.opacity(0.12))
            .frame(width: 190, height: 18)
            .blur(radius: 10)
            .offset(y: Self.shadowOffset)
    }

    private var flap: some View {
        OpenFlapShape()
            .fill(accentColor.secondary.swiftUIColor)
            .frame(width: Self.envelopeSize.width, height: Self.flapHeight)
            .scaleEffect(y: isFlapOpen ? 1 : 0.001, anchor: .bottom)
            .offset(y: Self.flapOffset)
    }

    private var envelopeBack: some View {
        RoundedRectangle(cornerRadius: IKRadius.small, style: .continuous)
            .fill(accentColor.secondary.swiftUIColor)
            .frame(width: Self.envelopeSize.width, height: Self.envelopeSize.height)
            .offset(y: Self.envelopeDrop)
    }

    private var letterOffset: CGFloat {
        let restingOffset = isLetterOut ? Self.letterOutOffset : Self.letterHiddenOffset
        return restingOffset - (isLetterFloating ? Self.floatAmplitude : 0)
    }

    private var letterLayer: some View {
        letter
            .offset(y: letterOffset)
            .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            .mask(alignment: .top) {
                Rectangle()
                    .frame(height: Self.maskHeight)
            }
    }

    private var letter: some View {
        VStack(alignment: .leading, spacing: IKPadding.mini) {
            ForEach(0 ..< Self.lineFractions.count, id: \.self) { index in
                Capsule()
                    .fill(MailResourcesAsset.textSecondaryColor.swiftUIColor.opacity(0.45))
                    .frame(width: Self.textContentWidth * Self.lineFractions[index], height: IKPadding.mini)
            }
        }
        .padding(IKPadding.medium)
        .frame(width: Self.letterSize.width, height: Self.letterSize.height, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: IKRadius.medium, style: .continuous)
                .fill(MailResourcesAsset.textFieldColor.swiftUIColor)
        )
        .shadow(color: .black.opacity(0.12), radius: IKPadding.mini, x: 0, y: IKPadding.micro)
    }

    private var pocket: some View {
        EnvelopePocketShape(notchDepth: Self.pocketNotchDepth)
            .fill(accentColor.primary.swiftUIColor)
            .frame(width: Self.envelopeSize.width, height: Self.envelopeSize.height)
            .offset(y: Self.envelopeDrop)
    }

    private var pocketCreases: some View {
        Path { path in
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: Self.envelopeSize.width / 2, y: Self.pocketNotchDepth))
            path.move(to: CGPoint(x: Self.envelopeSize.width, y: 0))
            path.addLine(to: CGPoint(x: Self.envelopeSize.width / 2, y: Self.pocketNotchDepth))
        }
        .stroke(Color.black.opacity(0.1), lineWidth: 1)
        .frame(width: Self.envelopeSize.width, height: Self.envelopeSize.height, alignment: .top)
        .offset(y: Self.envelopeDrop)
    }
}

// MARK: - Shapes

/// Triangle unfolding above the envelope, with its base on the envelope mouth
private struct OpenFlapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Front of the envelope, with a "V" shaped notch at the top center
private struct EnvelopePocketShape: Shape {
    let notchDepth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + notchDepth))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    EasterEggLetterView()
}
