// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        if intent is SearchIntent {
            return SearchIntentHandler()
        }
        return self
    }
    
}

class SearchIntentHandler: NSObject, SearchIntentHandling {
    func handle(intent: SearchIntent, completion: @escaping (SearchIntentResponse) -> Void) {
        
        completion(.success(result: "Response"))
    }
    
    func resolveAnything(for intent: SearchIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        
        guard let terms = intent.anything else {
            return completion(.confirmationRequired(with: intent.anything))
        }
        
        completion(.success(with: terms))
    }
}
