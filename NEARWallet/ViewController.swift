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

class ViewController: UIViewController {
    let webView = WKWebView()

    override func loadView() {
        self.view = webView

        webView.load("https://wallet.testnet.near.org")


        

    }

}

