/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

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

import PDFKit
import QuickLook
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct PreviewController: View {
    let url: URL
    let mimeType: String

    private var isPDF: Bool {
        if UTType(mimeType: mimeType)?.conforms(to: .pdf) == true {
            return true
        }

        return UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true
    }

    var body: some View {
        #if targetEnvironment(macCatalyst)
        if isPDF {
            PDFPreviewView(url: url)
        } else {
            QuickLookPreviewController(url: url)
        }
        #else
        QuickLookPreviewController(url: url)
        #endif
    }
}

private struct QuickLookPreviewController: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // Intentionally unimplemented...
    }

    class Coordinator: QLPreviewControllerDataSource {
        let parent: QuickLookPreviewController

        init(parent: QuickLookPreviewController) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }
    }
}

#if targetEnvironment(macCatalyst)
// On Mac Catalyst, the QuickLook preview is broken for PDF files.
// The QL preview displays a static image of the first page of the PDF, and does not allow scrolling.
private struct PDFPreviewView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        guard pdfView.document?.documentURL != url else { return }
        pdfView.document = PDFDocument(url: url)
    }
}
#endif
