//
//  RemoteContent.swift
//  LocalWKWebView
//
//  Created by Nikolay Dimolarov on 24.09.26.
//  Copyright © 2026 Nikolay Dimolarov. All rights reserved.
//

import Foundation
import ZIPFoundation

/// Downloads a zip with custom HTML, CSS and JS and unpacks it into Application Support,
/// so it can be loaded into the web view like any other local files.
nonisolated enum RemoteContent {
    static let zipURL = URL(string: "https://github.com/tech4242/wkwebview-local-resources/raw/master/custom_css_js.zip")!
    static let entryFile = "custom.html"

    enum Failure: LocalizedError {
        case badStatus(Int)
        case missingEntryFile

        var errorDescription: String? {
            switch self {
            case .badStatus(let code):
                "The server responded with HTTP \(code)."
            case .missingEntryFile:
                "The downloaded zip does not contain \(RemoteContent.entryFile)."
            }
        }
    }

    /// Downloads and unzips the content, replacing any previous download.
    @concurrent
    static func download() async throws -> WebContent {
        let (zipFile, response) = try await URLSession.shared.download(from: zipURL)
        defer { try? FileManager.default.removeItem(at: zipFile) }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw Failure.badStatus(status) }

        let fileManager = FileManager.default
        let destination = URL.applicationSupportDirectory.appending(path: "remote", directoryHint: .isDirectory)
        try? fileManager.removeItem(at: destination)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        try fileManager.unzipItem(at: zipFile, to: destination)

        // Don't assume how the zip is laid out, just find the HTML file in it.
        guard let entry = findFile(named: entryFile, in: destination) else {
            throw Failure.missingEntryFile
        }
        return WebContent(root: entry.deletingLastPathComponent(), entryPath: entryFile)
    }

    private static func findFile(named name: String, in folder: URL) -> URL? {
        let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)
        while let file = files?.nextObject() as? URL {
            if file.lastPathComponent == name { return file }
        }
        return nil
    }
}
