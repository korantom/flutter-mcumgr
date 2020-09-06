//
//  Data+Hex.swift
//  flutter_mcumgr
//
//  Created by Tomáš Koranda on 06/09/2020.
//

import Foundation

extension Data {
    internal var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    internal var hexStringUpper: String {
        map { String(format: "%02X", $0) }.joined()
    }
}

extension Data {
    func split(by length: Int) -> [Data] {
        var startIndex = self.startIndex
        var chunks = [Data]()
        
        while startIndex < endIndex {
            let endIndex = index(startIndex, offsetBy: length, limitedBy: self.endIndex) ?? self.endIndex
            chunks.append(subdata(in: startIndex..<endIndex))
            startIndex = endIndex
        }
        
        return chunks
    }
}
