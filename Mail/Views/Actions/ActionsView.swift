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

import MailCore
import MailResources
import SwiftUI

struct ActionsView: View {
    @StateObject var viewModel: ActionsViewModel

    init(target: ActionsTarget) {
        let viewModel = ActionsViewModel(target: target)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text("Que souhaitez-vous faire ?")
                .frame(maxWidth: .infinity, alignment: .leading)
                .textStyle(.bodySecondary)
            // Quick actions
            HStack(spacing: 28) {
                ForEach(viewModel.quickActions) { action in
                    QuickActionView(viewModel: viewModel, action: action)
                }
            }
            SeparatorView(withPadding: false, fullWidth: true)
            // Actions
            ForEach(viewModel.listActions) { action in
                ActionView(viewModel: viewModel, action: action)
            }
        }
        .padding([.leading, .trailing], 32)
        .padding(.top, 16)
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsView(target: .thread(PreviewHelper.sampleThread))
            .accentColor(Color(MailResourcesAsset.infomaniakColor.color))
    }
}

struct QuickActionView: View {
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    var body: some View {
        Button {
            viewModel.didTap(action: action)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(MailResourcesAsset.backgroundHeaderColor.color))

                    Image(resource: action.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(19)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                Text(action.title)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
        }
    }
}

struct ActionView: View {
    @ObservedObject var viewModel: ActionsViewModel
    let action: Action

    var body: some View {
        Button {
            viewModel.didTap(action: action)
        } label: {
            HStack {
                Image(resource: action.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
                Text(action.title)
                    .font(MailTextStyle.body.font)
            }
        }
    }
}
