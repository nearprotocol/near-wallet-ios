//
//  KeyUtils.swift
//  NEARWallet
//
//  Created by Vladimir Grichina on 5/29/20.
//  Copyright © 2020 NEAR Protocol. All rights reserved.
//

import Foundation

protocol GenericPasswordConvertible: CustomStringConvertible {
    /// Creates a key from a raw representation.
    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes

    /// A raw representation of the key.
    var rawRepresentation: Data { get }
}
