//
//  ViewController.swift
//  NEARWallet
//
//  Created by Vladimir Grichina on 5/22/20.
//  Copyright © 2020 NEAR Protocol. All rights reserved.
//

import UIKit
import WebKit
import nearclientios
import PromiseKit
import AwaitKit

extension WKWebView {
    func load(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            load(request)
        }
    }
}

//let WALLET_URL = "https://wallet.testnet.near.org"

let WALLET_URL = "https://a9bc92f45c1e.ngrok.io"

class ViewController: UIViewController, WKScriptMessageHandler {

    let keyStore = KeychainKeyStore()

    let contentController = WKUserContentController()
    lazy var webView: WKWebView = {
        self.contentController.add(self, name: "signer")
        let config = WKWebViewConfiguration()
        config.userContentController = self.contentController
        return WKWebView(frame: CGRect.zero, configuration: config)
    }()

    override func loadView() {
        self.view = webView

        webView.load(WALLET_URL)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("message.body type: \(type(of: message.body))")
        print("message: \((message.body as! NSObject).description.prefix(500))")
        if let body = message.body as? NSDictionary {
            let method = body["methodName"]! as! String
            let args = body["args"]! as! NSDictionary
            let requestId = body["requestId"]! as! NSNumber

            switch method {
            case "createKey":
                returnResult(requestId: requestId,
                             result: self.createKey(accountId: args["accountId"]! as! String, networkId: args["networkId"]! as! String))
            default:
                print("unknown method: \(method)")
            }
        }
    }

    func returnResult<T>(requestId: NSNumber, result: Promise<T>) -> Void where T : Encodable {
        firstly {
            result
        }.done { resultValue in
            let encoder = JSONEncoder()
            // TODO: Handle errors and pass to JS
            if let jsonData = try? encoder.encode(resultValue) {
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    self.webView.evaluateJavaScript("__walletCallback({ requestId: \(requestId),  result: \(jsonString)})") { (jsResult, jsError) in
                        print("jsResult: \(jsResult) jsError: \(jsError)")
                    }
                }
            }
        }.catch { _ in
            // TODO: Pass errors back to JS
        }
    }

    func createKey(accountId: String, networkId: String) -> Promise<String> {
        return async {
            if let keyPair = try await(self.keyStore.getKey(networkId: networkId, accountId: accountId)) {
                return keyPair.getPublicKey().toString()
            } else {
                let keyPair = try KeyPairEd25519.fromRandom()
                try await(self.keyStore.setKey(networkId: networkId, accountId: accountId, keyPair: keyPair))
                return keyPair.getPublicKey().toString()
            }
        }
    }
}

