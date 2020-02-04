// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import LocalAuthentication
import Shared

private let logger = Logger.browserLogger

public struct KeychainError: Error {
    public let domain: String
    public let code: Int32
    public let description: String?
    
    init(domain: String = "com.brave.keychain.error", code: Int32, description: String? = nil) {
        self.domain = domain
        self.code = code
        self.description = description
    }
}

extension Keychain {
    public static func getKeychain(secureEnclave: Bool, promptDescription: String? = nil) -> Keychain {
        return Keychain(secureEnclave: secureEnclave, promptDescription: promptDescription)
    }
    
    public func set<T: Codable>(key: String, data: T) -> Error? {
        let encodedData = try? JSONEncoder().encode(KeychainItem(data: data))
        
        if let data = encodedData {
            let err = setItem(key: key, data: data)
            if err != noErr {
                return KeychainError(code: err, description: nil)
            }
            
            return nil
        }
        
        return KeychainError(code: -1, description: "Data could not be serialized")
    }
    
    public func update<T: Codable>(key: String, data: T) -> Error? {
        let encodedData = try? JSONEncoder().encode(KeychainItem(data: data))
        
        if let data = encodedData {
            let err = updateItem(key: key, data: data)
            if err != noErr {
                return KeychainError(code: err, description: nil)
            }
            
            return nil
        }
        
        return KeychainError(code: -1, description: "Data could not be serialized")
    }
    
    public func get<T: Codable>(key: String) throws -> T? {
        let data = try retrieveItem(key: key)
        if let data = data, let result = try? JSONDecoder().decode(KeychainItem<T>.self, from: data) {
            return result.data
        }
        
        throw KeychainError(code: -1, description: "Data could not be serialized")
    }
    
    public func remove(key: String) -> Error? {
        let error = removeItem(key: key)
        
        if error != noErr {
            return KeychainError(code: error)
        }
        
        return nil
    }
    
    public var isBiometricsAvailable: Bool {
        var error: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logger.error("Keychain Access Error: \(error)")
        }
        
        return result
    }
    
    public var isTouchIDAvailable: Bool {
        var error: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logger.error("Keychain Access Error: \(error)")
        }
        
        return result && context.biometryType == .touchID
    }
    
    public var isFaceIDAvailable: Bool {
        var error: NSError?
        let result = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logger.error("Keychain Access Error: \(error)")
        }
        
        return result && context.biometryType == .faceID
    }
    
    public func prompt(_ completion: ((Bool, Error?) -> Void)? = nil) {
        if isBiometricsAvailable {
            invalidateContext()
            
            var reason = String()
            if isFaceIDAvailable {
                reason = Bundle.main.infoDictionary?["NSFaceIDUsageDescription"] as? String ?? String()
            } else if isTouchIDAvailable {
                reason = Bundle.main.infoDictionary?["NSTouchIDUsageDescription"] as? String ?? String()
            }

            context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: reason) { reply, error in
                DispatchQueue.main.async {
                    if let error = error {
                        logger.error("Keychain Prompt Error: \(error)")
                    }
                    
                    completion?(reply, error)
                }
            }
        }
    }
    
    private struct KeychainItem<T: Codable>: Codable {
        let data: T
    }
}

// MARK: - Private

public class Keychain {
    private let secureEnclave: Bool
    private let promptDescription: String?
    private let lock = NSRecursiveLock()
    private let queue = DispatchQueue(label: "com.brave.keychain.queue")
    
    private init(secureEnclave: Bool, promptDescription: String? = nil) {
        self.secureEnclave = secureEnclave
        self.promptDescription = promptDescription
        invalidateContext()
    }
    
    private func setItem(key: String, data: Data) -> OSStatus {
        var err = noErr
        
        hasItem(key: key) { [weak self] error, query, _ in
            guard let self = self else { return }
            if error == noErr || error == errSecDuplicateItem || error == errSecInteractionNotAllowed {
                err = self.updateItem(key: key, data: data)
            } else if error == errSecItemNotFound {
                var query = query
                
                if self.secureEnclave {
                    if let accessControl = self.secureReference {
                        query[kSecAttrAccessControl] = accessControl
                    }
                    
                    query[kSecUseAuthenticationUI] = kSecUseAuthenticationUIAllow
                    query[kSecUseAuthenticationContext] = self.context
                }
                
                if let promptDescription = self.promptDescription {
                    query[kSecUseOperationPrompt] = promptDescription
                }
                
                query[kSecValueData] = data
                query[kSecAttrAccessible] = nil
                query[kSecMatchLimit] = nil
                query[kSecReturnAttributes] = nil
                
                self.queue.sync {
                    err = SecItemAdd(query as CFDictionary, nil)
                }
            } else {
                err = error
            }
        }
        
        return err
    }
    
    private func updateItem(key: String, data: Data) -> OSStatus {
        var err = noErr
        
        hasItem(key: key) { [weak self] error, query, _ in
            guard let self = self else { return }
            if error == noErr || error == errSecDuplicateItem || error == errSecInteractionNotAllowed {
                var query = query
                let updateQuery = [kSecValueData: data]
                
                if self.secureEnclave {
                    if let accessControl = self.secureReference {
                        query[kSecAttrAccessControl] = accessControl
                    }
                    
                    query[kSecUseAuthenticationUI] = kSecUseAuthenticationUIAllow
                    query[kSecUseAuthenticationContext] = self.context
                }
                
                if let promptDescription = self.promptDescription {
                    query[kSecUseOperationPrompt] = promptDescription
                }
                
                query[kSecAttrAccessible] = nil
                query[kSecMatchLimit] = nil
                query[kSecReturnAttributes] = nil
                
                self.queue.sync {
                    err = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
                }
            } else if error == errSecItemNotFound {
                err = self.setItem(key: key, data: data)
            } else {
                err = error
            }
        }
        
        return err
    }
    
    private func retrieveItem(key: String) throws -> Data? {
        var err = noErr
        var res: Data?
        
        hasItem(key: key) { [weak self] error, query, result in
            guard let self = self else { return }
            if error == noErr || error == errSecInteractionNotAllowed {
                var query = result ?? query
                
                if self.secureEnclave {
                    if let accessControl = self.secureReference {
                        query[kSecAttrAccessControl] = accessControl
                    }
                    
                    query[kSecUseAuthenticationUI] = kSecUseAuthenticationUIAllow
                    query[kSecUseAuthenticationContext] = self.context
                }
                
                if let promptDescription = self.promptDescription {
                    query[kSecUseOperationPrompt] = promptDescription
                }
                
                query[kSecReturnData] = kCFBooleanTrue
                query[kSecClass] = kSecClassGenericPassword
                query[kSecAttrAccessible] = nil
                query[kSecReturnAttributes] = nil
                
                self.queue.sync {
                    var data: CFTypeRef?
                    err = SecItemCopyMatching(query as CFDictionary, &data)
                    
                    if err == noErr {
                        res = data as? Data
                    }
                }
            } else {
                err = error
            }
        }
        
        if err != noErr {
            throw KeychainError(code: err)
        }
        
        return res
    }
    
    private func removeItem(key: String) -> OSStatus {
        var err = noErr
        
        hasItem(key: key) { [weak self] error, query, _ in
            guard let self = self else { return }
            if error == noErr || error == errSecInteractionNotAllowed {
                var query = query
                
                if self.secureEnclave {
                    if let accessControl = self.secureReference {
                        query[kSecAttrAccessControl] = accessControl
                    }
                    
                    query[kSecUseAuthenticationUI] = kSecUseAuthenticationUIAllow
                    query[kSecUseAuthenticationContext] = self.context
                }
                
                if let promptDescription = self.promptDescription {
                    query[kSecUseOperationPrompt] = promptDescription
                }
                
                query[kSecAttrAccessible] = nil
                query[kSecMatchLimit] = nil
                query[kSecReturnAttributes] = nil
                
                self.queue.sync {
                    err = SecItemDelete(query as CFDictionary)
                }
            } else {
                err = error
            }
        }
        
        return err
    }
    
    private func hasItem(key: String, completion: @escaping (_ error: OSStatus, _ query: [CFString: Any], _ result: [CFString: Any]?) -> Void) {
        
        var accountQuery = [CFString: Any]()
        accountQuery[kSecClass] = kSecClassGenericPassword
        accountQuery[kSecAttrGeneric] = queue.label.data(using: .utf8)
        accountQuery[kSecMatchLimit] = kSecMatchLimitOne
        accountQuery[kSecReturnAttributes] = kCFBooleanTrue
        accountQuery[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        accountQuery[kSecUseAuthenticationUI] = kSecUseAuthenticationUIFail
        accountQuery[kSecAttrAccount] = key
        accountQuery[kSecAttrAccessible] = nil
        accountQuery[kSecUseOperationPrompt] = nil
        
        var result: CFTypeRef?
        var error: OSStatus = noErr
        
        queue.sync {
            error = SecItemCopyMatching(accountQuery as CFDictionary, &result)
        }
        
        completion(error, accountQuery, result as? [CFString: Any])
    }
    
    private var _context: LAContext?
    private var context: LAContext {
        get {
            lock.lock()
            if _context == nil {
                _context = LAContext()
                if let context = _context {
                    context.touchIDAuthenticationAllowableReuseDuration = LATouchIDAuthenticationMaximumAllowableReuseDuration
                }
            }
            lock.unlock()
            return _context! //swiftlint:disable:this force_unwrapping
        }
        
        set {
            _context = newValue
        }
    }
    
    private func invalidateContext() {
        lock.lock()
        _context?.invalidate()
        _context?.touchIDAuthenticationAllowableReuseDuration = 0
        _context = nil
        lock.unlock()
        context.touchIDAuthenticationAllowableReuseDuration = 0
    }
    
    private var secureReference: SecAccessControl? {
        var error: Unmanaged<CFError>?
        let secReference = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, &error)
        
        if let error = error {
            logger.error("Keychain Access Error: \(error.takeUnretainedValue())")
            return nil
        }
        
        return secReference
    }
}
