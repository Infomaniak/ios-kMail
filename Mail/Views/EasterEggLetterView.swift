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
import InfomaniakCore
import InfomaniakCoreCommonUI
import MailCore
import MailCoreUI
import MailResources
import SwiftUI

/// A name and email pair written on the envelope front
private struct EasterEggAddress {
    let name: String
    let email: String
}

/// Easter egg flow: an open envelope with a letter sliding out of it.
/// Tapping the envelope reveals its front, which can be dragged away to send the mail.
struct EasterEggLetterView: View {
    let draft: Draft
    let currentUser: UserProfile
    let mailboxManager: MailboxManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor

    @State private var isShowingEnvelopeFront = false
    @State private var isShowing = false
    @State private var isFlapOpen = false
    @State private var isLetterOut = false
    @State private var isLetterFloating = false

    // MARK: - View

    var body: some View {
        let content = ZStack(alignment: .top) {
            MailResourcesAsset.backgroundColor.swiftUIColor
                .ignoresSafeArea()

            HStack {
                Spacer()
                CloseButton { dismiss() }
                    .padding(.trailing, value: .medium)
                    .padding(.top, value: .small)
            }

            if isShowingEnvelopeFront {
                EnvelopeFrontView(
                    draft: draft,
                    currentUser: currentUser,
                    mailboxManager: mailboxManager,
                    onSent: dismiss.callAsFunction
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(1)
            } else {
                OpenEnvelopeIllustration(
                    accentColor: accentColor,
                    isFlapOpen: isFlapOpen,
                    isLetterOut: isLetterOut,
                    isLetterFloating: isLetterFloating,
                    onEnvelopeTapped: presentEnvelopeFront
                )
                .scaleEffect(isShowing ? 1 : 0.85)
                .opacity(isShowing ? 1 : 0)
                .transition(.opacity.combined(with: .scale(scale: 1.05)))
                .onAppear(perform: playAppearAnimation)
            }
        }
        .onTapGesture(perform: dismiss.callAsFunction)
        .matomoView(view: ["EasterEggLetterView"])

        if #available(iOS 27.1, *) {
            content
                .onHingeChange { _, newContext in
                    handleHingeContextChange(newContext)
                }
        } else {
            content
        }
    }

    // MARK: - Func

    private func presentEnvelopeFront() {
        setEnvelopeFrontVisible(true)
    }

    /// Matches the displayed phase to the hinge status: a closed phone shows the letter front,
    /// an open phone shows the open envelope
    @available(iOS 27.1, *)
    private func handleHingeContextChange(_ context: DeviceHingeContext) {
        guard let hinge = context.hinge else { return }

        setEnvelopeFrontVisible(hinge.status == .closed)
    }

    /// Shows or hides the envelope front with the phase transition animation
    private func setEnvelopeFrontVisible(_ isVisible: Bool) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.85)) {
            isShowingEnvelopeFront = isVisible
        }
    }

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

// MARK: - Open Envelope Illustration

/// An open envelope with a letter sliding out of it, drawn on a fixed 300x340 canvas.
private struct OpenEnvelopeIllustration: View {
    let accentColor: AccentColor
    let isFlapOpen: Bool
    let isLetterOut: Bool
    let isLetterFloating: Bool
    let onEnvelopeTapped: () -> Void

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
        .contentShape(Rectangle())
        .onTapGesture(perform: onEnvelopeTapped)
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

// MARK: - Envelope Front

/// Front of the envelope, like a real letter: sender and recipient addresses, a stamp with the Infomaniak logo.
/// It follows the finger when dragged and the mail is sent once a threshold is passed.
private struct EnvelopeFrontView: View {
    enum SendPhase {
        case ready, flying, sent
    }

    let draft: Draft
    let currentUser: UserProfile
    let mailboxManager: MailboxManager
    let onSent: () -> Void

    @AppStorage(UserDefaults.shared.key(.accentColor), store: .shared) private var accentColor = DefaultPreferences.accentColor

    @State private var dragOffset: CGSize = .zero
    @State private var sendPhase: SendPhase = .ready

    /// The mail is addressed to the sender when the draft has no recipient yet
    private var recipient: EasterEggAddress {
        draft.to.first.map { EasterEggAddress(name: $0.name, email: $0.email) } ?? sender
    }

    private var sender: EasterEggAddress {
        EasterEggAddress(name: currentUser.displayName, email: mailboxManager.mailbox.email)
    }

    // MARK: Geometry

    private static let envelopeSize = CGSize(width: 280, height: 184)
    /// Margin between the envelope and the screen edges
    private static let screenPadding = IKPadding.micro
    /// Minimum drag distance to send the mail
    private static let sendThreshold: CGFloat = 150
    /// How far the envelope travels beyond the drag distance when it is sent
    private static let escapeFactor: CGFloat = 12
    /// Maximum tilt of the envelope while it is dragged
    private static let maxTilt: CGFloat = 8

    private var cardTilt: CGFloat {
        let rawTilt = dragOffset.width / 18
        return min(max(rawTilt, -Self.maxTilt), Self.maxTilt)
    }

    /// Handwritten style font used for the addresses written on the envelope
    private static func addressFont(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom("Noteworthy-Bold", size: size, relativeTo: textStyle)
    }

    // MARK: - View

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if sendPhase == .sent {
                    SentBadgeView(accentColor: accentColor)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    envelopeCard
                        .scaleEffect(Self.envelopeScale(for: proxy.size))
                        .offset(dragOffset)
                        .onTapGesture {
                            // Swallows taps on the envelope so the screen level tap to dismiss is not triggered
                        }
                        .gesture(dragGesture)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .matomoView(view: ["EasterEggEnvelopeFront"])
        }
    }

    /// Scales the envelope so that it takes as much space as possible on screen
    private static func envelopeScale(for availableSize: CGSize) -> CGFloat {
        let horizontalScale = (availableSize.width - 2 * screenPadding) / envelopeSize.width
        let verticalScale = (availableSize.height - 2 * screenPadding) / envelopeSize.height
        return min(horizontalScale, verticalScale)
    }

    private var envelopeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: IKRadius.small, style: .continuous)
                .fill(accentColor.primary.swiftUIColor)
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    senderAddress
                        .padding(.leading, IKPadding.large)
                    Spacer()
                    PostmarkView(inkColor: accentColor.onAccent.swiftUIColor)
                        .offset(x: PostmarkView.size / 2, y: IKPadding.micro)
                        .zIndex(1)
                    StampView(perforationColor: accentColor.primary.swiftUIColor)
                        .padding(.trailing, IKPadding.medium)
                }
                .padding(.top, IKPadding.small)

                Spacer()

                recipientAddress
                    .frame(maxWidth: .infinity)
                    .offset(x: IKPadding.small)

                Spacer()
            }
        }
        .frame(width: Self.envelopeSize.width, height: Self.envelopeSize.height)
        .rotationEffect(.degrees(cardTilt))
    }

    private var senderAddress: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !sender.name.isEmpty && sender.name != sender.email {
                Text(sender.name)
                    .font(Self.addressFont(size: 11, relativeTo: .caption))
            }
            Text(sender.email)
                .font(Self.addressFont(size: 9.5, relativeTo: .caption2))
        }
        .foregroundStyle(accentColor.onAccent.swiftUIColor.opacity(0.85))
        .lineLimit(1)
    }

    private var recipientAddress: some View {
        VStack(spacing: 2) {
            if !recipient.name.isEmpty && recipient.name != recipient.email {
                Text(recipient.name)
                    .font(Self.addressFont(size: 20, relativeTo: .title3))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            Text(recipient.email)
                .font(Self.addressFont(size: 12, relativeTo: .caption))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .foregroundStyle(accentColor.onAccent.swiftUIColor)
        .padding(.horizontal, IKPadding.medium)
    }

    // MARK: - Func

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard sendPhase == .ready else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard sendPhase == .ready else { return }

                let distance = hypot(value.translation.width, value.translation.height)
                guard distance >= Self.sendThreshold else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                        dragOffset = .zero
                    }
                    return
                }

                sendMail(with: value.translation)
            }
    }

    private func sendMail(with translation: CGSize) {
        sendPhase = .flying
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.easeIn(duration: 0.45)) {
            dragOffset = CGSize(width: translation.width * Self.escapeFactor, height: translation.height * Self.escapeFactor)
        }

        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                sendPhase = .sent
            }

            try? await Task.sleep(for: .seconds(1.2))
            onSent()
        }
    }
}

/// Green light confirming that the mail was sent
private struct SentBadgeView: View {
    let accentColor: AccentColor

    private static let badgeDiameter: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .fill(accentColor.primary.swiftUIColor)
                .frame(width: Self.badgeDiameter, height: Self.badgeDiameter)
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(accentColor.onAccent.swiftUIColor)
        }
    }
}

// MARK: - Stamp

/// Postage stamp with the Infomaniak logo and a perforated edge
private struct StampView: View {
    let perforationColor: Color

    fileprivate static let size = CGSize(width: 62, height: 76)
    fileprivate static let holeDiameter: CGFloat = 5
    fileprivate static let holeSpacing: CGFloat = 11
    private static let logoWidth: CGFloat = 44

    var body: some View {
        ZStack {
            Rectangle()
                .fill(MailResourcesAsset.textFieldColor.swiftUIColor)

            MailResourcesAsset.splashscreenInfomaniak.swiftUIImage
                .resizable()
                .scaledToFit()
                .frame(width: Self.logoWidth)

            Rectangle()
                .stroke(perforationColor.opacity(0.3), lineWidth: 1)
                .frame(
                    width: Self.size.width - Self.holeDiameter * 2,
                    height: Self.size.height - Self.holeDiameter * 2
                )

            StampPerforationShape(holeDiameter: Self.holeDiameter, holeSpacing: Self.holeSpacing)
                .fill(perforationColor)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

/// Holes punched along the edges of the stamp
private struct StampPerforationShape: Shape {
    let holeDiameter: CGFloat
    let holeSpacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = holeDiameter / 2

        let columns = max(1, Int(rect.width / holeSpacing))
        let columnStep = rect.width / CGFloat(columns + 1)
        for column in 1 ... columns {
            let x = CGFloat(column) * columnStep
            path.addEllipse(in: CGRect(x: x - radius, y: rect.minY - radius, width: holeDiameter, height: holeDiameter))
            path.addEllipse(in: CGRect(x: x - radius, y: rect.maxY - radius, width: holeDiameter, height: holeDiameter))
        }

        let rows = max(1, Int(rect.height / holeSpacing))
        let rowStep = rect.height / CGFloat(rows + 1)
        for row in 1 ... rows {
            let y = CGFloat(row) * rowStep
            path.addEllipse(in: CGRect(x: rect.minX - radius, y: y - radius, width: holeDiameter, height: holeDiameter))
            path.addEllipse(in: CGRect(x: rect.maxX - radius, y: y - radius, width: holeDiameter, height: holeDiameter))
        }

        return path
    }
}

/// Ink marks over the stamp, like on a stamped letter
private struct PostmarkView: View {
    let inkColor: Color

    fileprivate static let size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .stroke(inkColor.opacity(0.55), lineWidth: 1.5)
            VStack(spacing: 3) {
                Capsule()
                    .fill(inkColor.opacity(0.55))
                    .frame(width: 24, height: 1.5)
                Capsule()
                    .fill(inkColor.opacity(0.55))
                    .frame(width: 16, height: 1.5)
            }
        }
        .frame(width: Self.size, height: Self.size)
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
    let draft = Draft()
    draft.to.append(objectsIn: [Recipient(email: "camille.martin@infomaniak.com", name: "Camille Martin")])
    return EasterEggLetterView(
        draft: draft,
        currentUser: PreviewHelper.sampleUser,
        mailboxManager: PreviewHelper.sampleMailboxManager
    )
}
