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

import InfomaniakCore
import InfomaniakCoreUI
import InfomaniakDI
import MailCore
import MailResources
import RealmSwift
import SwiftUI

struct AttachmentPreview: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedRealmObject var attachment: Attachment

    @Environment(\.verticalSizeClass) var sizeClass

    var body: some View {
        NavigationView {
            Group {
                if let url = attachment.localUrl, FileManager.default.fileExists(atPath: url.path) {
                    PreviewController(url: url)
                } else {
                    ProgressView()
                }
            }
            .navigationBarTitle(attachment.name, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label(MailResourcesStrings.Localizable.buttonClose, systemImage: "xmark")
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: download) {
                        Label {
                            Text(MailResourcesStrings.Localizable.buttonDownload)
                                .font(MailTextStyle.labelSecondary.font)
                        } icon: {
                            Image(resource: MailResourcesAsset.download)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                        .dynamicLabelStyle(sizeClass: sizeClass ?? .regular)
                    }
                    Spacer()
                }
            }
        }
    }

    private func download() {
        @InjectService var matomo: MatomoUtils
        matomo.track(eventWithCategory: .message, name: "download")
        guard let url = attachment.localUrl,
              var source = UIApplication.shared.mainSceneKeyWindow?.rootViewController else {
            return
        }
        if let presentedViewController = source.presentedViewController {
            source = presentedViewController
        }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = source.view
        source.present(vc, animated: true)
    }
}

struct AttachmentPreview_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentPreview(attachment: PreviewHelper.sampleAttachment)
    }
}
