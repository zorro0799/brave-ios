/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

#if canImport(WidgetKit)
import WidgetKit
#endif

open class BraveGlobalShieldStats {
    public static let shared = BraveGlobalShieldStats()
    public static let didUpdateNotification = "BraveGlobalShieldStatsDidUpdate"
    
    public var adblock: Int = 0 {
        didSet {
            Preferences.BlockStats.adsCount.value = adblock
            postUpdateNotification()
        }
    }

    public var trackingProtection: Int = 0 {
        didSet {
            Preferences.BlockStats.trackersCount.value = trackingProtection
            postUpdateNotification()
        }
    }

    public var httpse: Int = 0 {
        didSet {
            Preferences.BlockStats.httpsUpgradeCount.value = httpse
            postUpdateNotification()
        }
    }
    
    public var scripts: Int = 0 {
        didSet {
            Preferences.BlockStats.scriptsCount.value = scripts
            postUpdateNotification()
        }
    }
    
    public var images: Int = 0 {
        didSet {
            Preferences.BlockStats.imagesCount.value = images
            postUpdateNotification()
        }
    }
    
    public var safeBrowsing: Int = 0 {
        didSet {
            Preferences.BlockStats.phishingCount.value = safeBrowsing
            postUpdateNotification()
        }
    }
    
    public var fpProtection: Int = 0 {
        didSet {
            Preferences.BlockStats.fingerprintingCount.value = fpProtection
            postUpdateNotification()
        }
    }
    
    private func postUpdateNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: BraveGlobalShieldStats.didUpdateNotification), object: nil)
        if #available(iOS 14, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "StatWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "StatsWidget")
        }
    }

    fileprivate init() {
        adblock = Preferences.BlockStats.adsCount.value
        trackingProtection = Preferences.BlockStats.trackersCount.value
        httpse = Preferences.BlockStats.httpsUpgradeCount.value
        images = Preferences.BlockStats.imagesCount.value
        scripts = Preferences.BlockStats.scriptsCount.value
        fpProtection = Preferences.BlockStats.fingerprintingCount.value
        safeBrowsing = Preferences.BlockStats.phishingCount.value
    }
    
    fileprivate let millisecondsPerItem: Int = 50
    
    public var timeSaved: String {
        get {
            let estimatedMillisecondsSaved = (adblock + trackingProtection) * millisecondsPerItem
            let hours = estimatedMillisecondsSaved < 1000 * 60 * 60 * 24
            let minutes = estimatedMillisecondsSaved < 1000 * 60 * 60
            let seconds = estimatedMillisecondsSaved < 1000 * 60
            var counter: Double = 0
            var text = ""
            
            if seconds {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000))
                text = Strings.shieldsTimeStatsSeconds
            } else if minutes {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60))
                text = Strings.shieldsTimeStatsMinutes
            } else if hours {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60 / 60))
                text = Strings.shieldsTimeStatsHour
            } else {
                counter = ceil(Double(estimatedMillisecondsSaved / 1000 / 60 / 60 / 24))
                text = Strings.shieldsTimeStatsDays
            }
            
            if let counterLocaleStr = Int(counter).decimalFormattedString {
                return counterLocaleStr + text
            } else {
                return "0" + Strings.shieldsTimeStatsSeconds     // If decimalFormattedString returns nil, default to "0s"
            }
        }
    }
}

private extension Int {
    var decimalFormattedString: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        numberFormatter.locale = NSLocale.current
        return numberFormatter.string(from: self as NSNumber)
    }
}
