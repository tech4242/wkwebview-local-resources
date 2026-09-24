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

/// How local files get into the web view.
enum LoadingMethod: String, CaseIterable, Identifiable {
    /// `loadFileURL(_:allowingReadAccessTo:)`: simple, but the page has no origin.
    case fileURL = "file://"
    /// A `WKURLSchemeHandler` serving the files: the page behaves like it's on a server.
    case customScheme = "app://"

    var id: Self { self }
}

/// Wraps a `WKWebView` for SwiftUI on both iOS and macOS.
struct WebView {
    let content: WebContent
    var method = LoadingMethod.fileURL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    fileprivate func makeWebView(coordinator: Coordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Scheme handlers can only be registered before the web view is created.
        configuration.setURLSchemeHandler(coordinator.schemeHandler, forURLScheme: LocalSchemeHandler.scheme)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        #if DEBUG
        // Lets you attach Safari's Web Inspector (Develop menu) to the page.
        webView.isInspectable = true
        #endif
        return webView
    }

    fileprivate func update(_ webView: WKWebView, coordinator: Coordinator) {
        // Only reload when something changes, not on every SwiftUI update.
        guard coordinator.loadedContent != content || coordinator.loadedMethod != method else { return }
        coordinator.loadedContent = content
        coordinator.loadedMethod = method

        switch method {
        case .fileURL:
            let fileURL = content.root.appending(path: content.entryPath)
            webView.loadFileURL(fileURL, allowingReadAccessTo: content.root)
        case .customScheme:
            coordinator.schemeHandler.root = content.root
            webView.load(URLRequest(url: LocalSchemeHandler.url(for: content.entryPath)))
        }
    }

    final class Coordinator {
        let schemeHandler = LocalSchemeHandler()
        var loadedContent: WebContent?
        var loadedMethod: LoadingMethod?
    }
}

#if os(macOS)
extension WebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        update(webView, coordinator: context.coordinator)
    }
}
#else
extension WebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        update(webView, coordinator: context.coordinator)
    }
}
#endif
