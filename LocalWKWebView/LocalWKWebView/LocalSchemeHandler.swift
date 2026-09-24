//
//  LocalSchemeHandler.swift
//  LocalWKWebView
//
//  Created by Nikolay Dimolarov on 24.09.26.
//  Copyright © 2026 Nikolay Dimolarov. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves files from a local folder under a custom URL scheme, e.g. `app://local/index.html`.
///
/// Pages loaded from file:// get a `null` origin, so fetch(), XHR, ES modules and
/// anything else that needs same-origin access fail. Pages served from a custom
/// scheme get a real origin, so all of that works just like on a web server.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "app"
    static let host = "local"

    /// Folder that requests are resolved against.
    var root: URL?

    static func url(for path: String) -> URL {
        URL(string: "\(scheme)://\(host)/")!.appending(path: path)
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        guard let root, let url = task.request.url else {
            task.didFailWithError(URLError(.badURL))
            return
        }

        let rootPath = root.standardizedFileURL.path
        let file = root.appending(path: url.path(percentEncoded: false)).standardizedFileURL

        // Refuse anything that resolves outside of root, e.g. app://local/../../secret
        guard file.path.hasPrefix(rootPath + "/"), let data = try? Data(contentsOf: file) else {
            respond(to: task, url: url, status: 404, mimeType: "text/plain", data: Data("Not found".utf8))
            return
        }

        let mimeType = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        respond(to: task, url: url, status: 200, mimeType: mimeType, data: data)
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {
        // Every request is answered synchronously in start, so there is nothing to cancel.
    }

    private func respond(to task: any WKURLSchemeTask, url: URL, status: Int, mimeType: String, data: Data) {
        let headers = [
            "Content-Type": mimeType,
            "Content-Length": String(data.count),
        ]
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }
}
