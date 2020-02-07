// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        guard intent is SearchIntent else {
            return self
        }
        return SearchIntentHandler()
    }
    
}

class SearchIntentHandler: NSObject, SearchIntentHandling {
    
    func handle(intent: SearchIntent, completion: @escaping (SearchIntentResponse) -> Void) {
        guard let endpoint = intent.endpoint else {
            completion(SearchIntentResponse(code: .failure, userActivity: nil))
            return
        }
        
        completion(SearchIntentResponse.success(bookmarks: endpoint))
    }
    
}
