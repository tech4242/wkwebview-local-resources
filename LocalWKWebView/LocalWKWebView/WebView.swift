//
//  WebView.swift
//  LocalWKWebView
//
//  Created by Nikolay Dimolarov on 24.09.26.
//  Copyright © 2026 Nikolay Dimolarov. All rights reserved.
//

import SwiftUI
import WebKit

/// A local web page: a folder on disk plus the HTML file inside it to open.
struct WebContent: Equatable {
    /// Folder the page may read from (HTML, CSS, JS, images...).
    var root: URL
    /// Path of the HTML file, relative to `root`.
    var entryPath: String

    /// The `web` folder shipped in the app bundle.
    static let bundled = WebContent(
        root: Bundle.main.resourceURL!.appending(path: "web", directoryHint: .isDirectory),
        entryPath: "index.html"
    )
}

/// Wraps a `WKWebView` for SwiftUI on both iOS and macOS.
struct WebView {
    let content: WebContent

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    fileprivate func makeWebView() -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        #if DEBUG
        // Lets you attach Safari's Web Inspector (Develop menu) to the page.
        webView.isInspectable = true
        #endif
        return webView
    }

    fileprivate func update(_ webView: WKWebView, coordinator: Coordinator) {
        // Only reload when the content changes, not on every SwiftUI update.
        guard coordinator.loadedContent != content else { return }
        coordinator.loadedContent = content

        let fileURL = content.root.appending(path: content.entryPath)
        webView.loadFileURL(fileURL, allowingReadAccessTo: content.root)
    }

    final class Coordinator {
        var loadedContent: WebContent?
    }
}

#if os(macOS)
extension WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        makeWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        update(webView, coordinator: context.coordinator)
    }
}
#else
extension WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        update(webView, coordinator: context.coordinator)
    }
}
#endif
