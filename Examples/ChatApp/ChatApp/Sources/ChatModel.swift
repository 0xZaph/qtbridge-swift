// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

import Foundation
import QtBridge

@MainActor
@QtBridgeable
public final class Message {
    var author: String
    var textmessage: String
    var date: String

    public init(author: String, textmessage: String, date: String) {
        self.author = author
        self.textmessage = textmessage
        self.date = date
    }
}

@MainActor
@QtBridgeable
public final class ChatModel {

    public var msgs: QListModel<Message> = []

    public init() {
        msgs.append(
            Message(
                author: "Special Agent Dale Cooper",
                textmessage: "The owls are not what they seem.",
                date: "Feb 1989"
            )
        )
    }

    nonisolated
    private static let replies = [
        "Hello!",
        "Damn good coffee!",
        "See you at the Roadhouse.",
        "Every day, once a day, give yourself a present.",
        "Another case, another day.",
        "I have no idea where this will lead us.",
        "Let’s talk at the sheriff’s station.",
        "A path is formed by laying one stone at a time.",
        "I’ll bring the tape recorder."
    ]

    @concurrent
    nonisolated
    private static func generateReply() async -> String {
        try? await Task.sleep(for: .seconds(1))

        return replies.randomElement() ?? "..."
    }

    public func insertReply(
        author: String,
        text: String,
        date: String
    ) async {
        msgs.append(
            Message(
                author: author,
                textmessage: text,
                date: date
            )
        )

        guard author == "Me", !text.isEmpty else {
            return
        }

        let reply = await Self.generateReply()

        msgs.append(
            Message(
                author: "Special Agent Dale Cooper",
                textmessage: reply,
                date: Date.now.formatted(
                    date: .omitted,
                    time: .shortened
                )
            )
        )
    }

    public func clearMessages() {
        msgs.reset()
    }
}