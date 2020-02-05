// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit

class PasscodeViewController: UIViewController {
    
    private let passcodeView = PasscodeView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(passcodeView)
        passcodeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
