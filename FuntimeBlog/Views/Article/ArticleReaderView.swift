import SwiftUI
import WebKit
import UIKit

struct ArticleReaderView: UIViewRepresentable {
    let html: String
    var onOpenLink: (URL) -> Void = { _ in }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        let data = Data(html.utf8)
        webView.load(data,
                     mimeType: "text/html",
                     characterEncodingName: "UTF-8",
                     baseURL: URL(string: "https://www.funtime.com.tw")!)
    }

    func makeCoordinator() -> Coordinator { Coordinator(onOpenLink: onOpenLink) }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var loadedHTML: String?
        let onOpenLink: (URL) -> Void
        weak var webView: WKWebView?

        init(onOpenLink: @escaping (URL) -> Void) {
            self.onOpenLink = onOpenLink
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let y = scrollView.contentOffset.y
            webView?.evaluateJavaScript("window.__heroScroll && window.__heroScroll(\(y))")
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                onOpenLink(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
