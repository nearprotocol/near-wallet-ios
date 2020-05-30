//
//  ViewController.swift
//  NEARWallet
//
//  Created by Vladimir Grichina on 5/22/20.
//  Copyright © 2020 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}

class ViewController: UIViewController, WKScriptMessageHandler {


    let contentController = WKUserContentController()
    lazy var webView: WKWebView = {
        self.contentController.add(self, name: "signer")
        let config = WKWebViewConfiguration()
        config.userContentController = self.contentController
        return WKWebView(frame: CGRect.zero, configuration: config)
    }()

    override func loadView() {
        self.view = webView

        webView.load("https://wallet.testnet.near.org")

        webView.evaluateJavaScript("window.webkit.messageHandlers.signer.postMessage({foo:'bar'})")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        let body = message.body as! NSDictionary
        print("body: \(body.description.prefix(500))")
        //let method = body["method"]! as! String

    }
}

