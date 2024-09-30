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
    let threadIds: [String]

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plainText)
    }
}

struct DropThreadHandler: ViewModifier {
    @EnvironmentObject private var mailboxManager: MailboxManager
    @EnvironmentObject private var actionsManager: ActionsManager

    let destinationFolder: Folder

    func body(content: Content) -> some View {
        if #available(macCatalyst 16.0, iOS 16.0, *) {
            content
                .dropDestination(for: DraggedThread.self) { draggedThreads, _ in
                    for thread in draggedThreads {
                        handleDroppedThreads(thread)
                    }
                    return true
                }
        } else {
            content
        }
    }

    @available(macCatalyst 16.0, iOS 16.0, *)
    private func handleDroppedThreads(_ draggedThreads: DraggedThread) {
        var messages: [Message] = []
        var originFolder: Folder?
        for threadId in draggedThreads.threadIds {
            if let threadObject = mailboxManager.getThread(from: threadId),
               let threadFolder = threadObject.folder?.freezeIfNeeded() {
                guard !threadFolder.isEqual(destinationFolder) else { return }

                messages += threadObject.messages.freezeIfNeeded().toArray()
                guard originFolder != nil else {
                    originFolder = threadFolder
                    continue
                }
            }
        }

        if let originFolder {
            Task {
                await tryOrDisplayError {
                    try await actionsManager.performMove(
                        messages: messages,
                        from: originFolder,
                        to: destinationFolder
                    )
                }
            }
        }
    }
}

struct DraggableThread: ViewModifier {
    let draggedThreadId: [String]

    func body(content: Content) -> some View {
        if #available(macCatalyst 16.0, iOS 16.0, *) {
            content
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 7))
            #if os(macOS) || targetEnvironment(macCatalyst)
                .draggable(DraggedThread(threadIds: draggedThreadId)) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "envelope.fill")
                            .font(MailTextStyle.labelDraggableThread.font)
                            .padding(value: .small)
                        if draggedThreadId.count > 1 {
                            Text("\(draggedThreadId.count)")
                                .padding(value: .small)
                                .background(MailTextStyle.bodySmallAccent.color)
                                .font(MailTextStyle.bodySmallAccent.font)
                                .clipShape(Circle())
                        }
                    }
                }
            #else
                .draggable(DraggedThread(threadIds: draggedThreadId))
            #endif
        } else {
            content
        }
    }
}

extension View {
    func dropThreadHandler(destinationFolder: Folder) -> some View {
        modifier(DropThreadHandler(destinationFolder: destinationFolder))
    }

    func draggableThread(_ draggedThreadIds: [String]) -> some View {
        modifier(DraggableThread(draggedThreadId: draggedThreadIds))
    }
}
