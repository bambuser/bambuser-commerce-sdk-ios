//
//  WebPageView.swift
//  Example
//
//  Created by Saeid Basirnia on 2025-10-03.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct WebPageSheet: View {
    @EnvironmentObject var nav: NavigationManager
    let url: URL

    var body: some View {
        ZStack(alignment: .topLeading) {
            WebView(url: url)
                .ignoresSafeArea()

            Button {
                nav.dismissSheet()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 12)
            .padding(.leading, 12)
        }
    }
}
