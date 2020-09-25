// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import SwiftKeychainWrapper

extension BraveSyncAPI {
    
    var isInSyncGroup: Bool {
        if let codeWords = KeychainWrapper.standard.string(forKey: "BraveSyncV2_CodeWords"), !codeWords.isEmpty {
            return true
        }
        return false
    }
    
    var codeWords: String {
        get {
            if let codeWords = KeychainWrapper.standard.string(forKey: "BraveSyncV2_CodeWords"), !codeWords.isEmpty {
                return codeWords
            }
            
            let codeWords = BraveSyncAPI.shared.getSyncCode()
            KeychainWrapper.standard.set(codeWords, forKey: "BraveSyncV2_CodeWords")
            return codeWords
        }
        
        set {
            if BraveSyncAPI.shared.setSyncCode(newValue) {
                KeychainWrapper.standard.set(newValue, forKey: "BraveSyncV2_CodeWords")
            }
        }
    }
    
    func leaveSyncGroup() {
        BraveSyncAPI.shared.resetSync()
        KeychainWrapper.standard.removeObject(forKey: "BraveSyncV2_CodeWords")
    }
}
