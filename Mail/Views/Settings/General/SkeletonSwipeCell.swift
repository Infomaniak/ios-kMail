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

struct SkeletonSwipeCell: View {
    let isLeading: Bool
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .background {
                if isLeading {
                    leadingSkeletonView
                } else {
                    trailingSkeletonView
                }
            }
    }

    var leadingSkeletonView: some View {
        HStack(spacing: 16) {
            VStack {
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 30)
                Spacer()
            }
            VStack(alignment: .leading) {
                Capsule()
                    .fill(Color(uiColor: .systemGray3))
                    .frame(width: 72, height: 12)
                Capsule()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 8)
                    .padding(.trailing, -16)
                Capsule()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(height: 8)
                    .padding(.trailing, -16)
                Spacer()
            }
        }
        .padding([.leading, .vertical], 16)
        .frame(height: 80)
    }

    var trailingSkeletonView: some View {
        GeometryReader { reader in
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: reader.size.width - 48,
                               height: 8)
                        .padding(.leading, -16)
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: reader.size.width / 2,
                               height: 8)
                        .padding(.leading, -16)
                }
                VStack(alignment: .trailing) {
                    Capsule()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 48, height: 8)
                        .padding(.bottom, 24)
                    Image(resource: MailResourcesAsset.star)
                        .resizable()
                        .foregroundColor(Color(uiColor: .systemGray5))
                        .frame(width: 16, height: 16)
                }
            }
        }
        .padding([.trailing, .vertical], 16)
        .frame(height: 80)
    }
}

struct SkeletonSwipeCell_Previews: PreviewProvider {
    static var previews: some View {
        SwipeConfigCell(section: .leadingSwipe)
        SwipeConfigCell(section: .trailingSwipe)
    }
}
