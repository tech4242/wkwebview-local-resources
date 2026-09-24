//
//  ContentView.swift
//  LocalWKWebView
//
//  Created by Nikolay Dimolarov on 24.09.26.
//  Copyright © 2026 Nikolay Dimolarov. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    enum Source: String, CaseIterable, Identifiable {
        case bundled = "Bundled"
        case downloaded = "Downloaded"

        var id: Self { self }
    }

    enum DownloadState {
        case notStarted
        case inProgress
        case finished(WebContent)
        case failed(any Error)
    }

    @AppStorage("source") private var source = Source.bundled
    @State private var download = DownloadState.notStarted

    var body: some View {
        VStack(spacing: 0) {
            Picker("Source", selection: $source) {
                ForEach(Source.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            switch source {
            case .bundled:
                WebView(content: .bundled)
            case .downloaded:
                downloadedContent
            }
        }
        .task(id: source) {
            if source == .downloaded, case .notStarted = download {
                await startDownload()
            }
        }
    }

    @ViewBuilder
    private var downloadedContent: some View {
        switch download {
        case .notStarted, .inProgress:
            ProgressView("Downloading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .finished(let content):
            WebView(content: content)
        case .failed(let error):
            ContentUnavailableView {
                Label("Download failed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Try Again") {
                    Task { await startDownload() }
                }
            }
        }
    }

    private func startDownload() async {
        download = .inProgress
        do {
            download = .finished(try await RemoteContent.download())
        } catch {
            download = .failed(error)
        }
    }
}

#Preview {
    ContentView()
}
