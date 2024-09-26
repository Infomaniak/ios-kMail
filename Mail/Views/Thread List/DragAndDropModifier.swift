//
//  DragAndDropModifier.swift
//
//
//  Created by Jordan on 26.09.2024.
//

import MailCore
import SwiftUI

@available(macCatalyst 16.0, iOS 16.0, *)
struct DraggedThread: Transferable, Codable {
    let threadId: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }
}

struct DropThreadHandler: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager

    let destinationFolder: Folder

    func body(content: Content) -> some View {
        if #available(macCatalyst 16.0, iOS 16.0, *) {
            content
                .dropDestination(for: DraggedThread.self) { items, _ in
                    for item in items {
                        handleDroppedThread(item.threadId)
                    }
                    return true
                }
        } else {
            content
        }
    }

    private func handleDroppedThread(_ threadId: String) {
        if let threadObject = mailboxManager.getThread(from: threadId), let originFolder = threadObject.folder?.freezeIfNeeded() {
            let messages = threadObject.messages.freezeIfNeeded().toArray()
            Task {
                try await mailboxManager.move(messages: messages, to: destinationFolder, origin: originFolder)
            }
        }
    }
}

struct DraggableThread: ViewModifier {
    let draggedThreadId: String

    func body(content: Content) -> some View {
        if #available(macCatalyst 16.0, iOS 16.0, *) {
            content
                .draggable(DraggedThread(threadId: draggedThreadId))
        } else {
            content
        }
    }
}

extension View {
    func dropThreadHandler(destinationFolder: Folder) -> some View {
        modifier(DropThreadHandler(destinationFolder: destinationFolder))
    }

    func draggableThread(_ draggedThreadId: String) -> some View {
        modifier(DraggableThread(draggedThreadId: draggedThreadId))
    }
}
