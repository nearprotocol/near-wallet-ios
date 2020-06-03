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

let WALLET_URL = "https://near-wallet-pr-636.onrender.com"

class ViewController: UIViewController, WKScriptMessageHandler {

    lazy var signer: Signer = {
        return InMemorySigner(keyStore: KeychainKeyStore())
    }()

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
                             result: self.createKey(accountId: args["accountId"]! as! String,
                                                    networkId: args["networkId"]! as! String))
            case "getPublicKey":
                returnResult(requestId: requestId,
                             result: self.getPublicKey(accountId: args["accountId"]! as! String,
                                                       networkId: args["networkId"]! as! String))
            case "signMessage":
                returnResult(requestId: requestId,
                             result: self.signMessage(message: args["message"]! as! String, accountId: args["accountId"]! as! String,
                                                    networkId: args["networkId"]! as! String))

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
                    let jsCallback = "__walletCallback({ requestId: \(requestId),  result: \(jsonString)})"
                    print("jsCallback: \(jsCallback)")
                    self.webView.evaluateJavaScript(jsCallback  ) { (jsResult, jsError) in
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
            let publicKey = try await(self.signer.createKey(accountId: accountId, networkId: networkId))
            return publicKey.toString()
        }
    }

    func getPublicKey(accountId: String, networkId: String) -> Promise<String?> {
        return async {
            if let publicKey = try await(self.signer.getPublicKey(accountId: accountId, networkId: networkId)) {
                return publicKey.toString()
            }

            return nil
        }
    }

    func signMessage(message: String, accountId: String, networkId: String) -> Promise<String> {
        return async {
            let messageData = Data(base64Encoded: message)!
            let signature = try! await(self.signer.signMessage(message: [UInt8](messageData), accountId: accountId, networkId: networkId))
            // TODO: Make sure errors (like key not available) propagated properly
            return Data(signature.signature).base64EncodedString()
        }
    }
}

