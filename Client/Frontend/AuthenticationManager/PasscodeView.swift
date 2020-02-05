// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import SnapKit

class PasscodeView: UIView {
    private let titleLabel = UILabel().then {
        $0.text = "Enter your passcode"
    }
    
    private let passcodeField = PasscodeMaskView(fieldCount: 6)
    
    private let attemptsView = PasscodeAttemptsView().then {
        $0.isHidden = true
    }
    
    private let stackView = UIStackView().then {
        $0.spacing = 25.0
        $0.axis = .vertical
        $0.alignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(passcodeField)
        stackView.addArrangedSubview(attemptsView)
        
        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.left.greaterThanOrEqualToSuperview().offset(15.0)
            $0.right.lessThanOrEqualToSuperview().offset(-15.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class PasscodeMaskView: UIView, UITextFieldDelegate {
    
    public var isPasscodeValid: (([String]) -> Bool)?
    
    public var fields: [UITextField] {
        return stackView.arrangedSubviews.compactMap({ $0 as? UITextField })
    }
    
    private let stackView = UIStackView().then {
        $0.spacing = 15.0
        $0.distribution = .fillEqually
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(equalInset: 15.0)
    }
    
    public init(fieldCount: UInt) {
        super.init(frame: .zero)
        
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        for i in 0..<fieldCount {
            stackView.addArrangedSubview(newField().then {
                $0.tag = Int(i)
            })
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func newField() -> BackspaceableTextField {
        return BackspaceableTextField().then {
            $0.textAlignment = .center
            $0.textColor = .lightGray
            $0.tintColor = .clear
            $0.font = nil
            $0.font = UIFont.systemFont(ofSize: 30.0, weight: .bold)
            $0.layer.borderWidth = 1.0
            $0.layer.cornerRadius = 10.0
            $0.layer.borderColor = UIColor.lightGray.cgColor
            $0.backgroundColor = .clear
            $0.keyboardType = .numberPad
            $0.isSecureTextEntry = false
            $0.delegate = self
            $0.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
            
            $0.snp.makeConstraints {
                $0.width.height.equalTo(20.0)
            }
            
            $0.onBackspace = { [weak self] in
                let index = $0.tag - 1
                let delayFocusOwner = false
                if index >= 0, let previousField = self?.stackView.arrangedSubviews[index] as? UITextField {
                    if (delayFocusOwner && !$1) || !delayFocusOwner {
                        previousField.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        (textField as? BackspaceableTextField)?.cachedString = string
        textField.backgroundColor = string.isEmpty ? .clear : .lightGray
        textField.text = " "
        
        if !string.isEmpty {
            self.textFieldDidChange(textField)
        }
        
        return string.isEmpty
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        stackView.arrangedSubviews.forEach {
            ($0 as? BackspaceableTextField)?.hasFocus = $0 == textField
        }
        return true
    }
    
    @objc
    func textFieldDidChange(_ textField: UITextField) {
        let index = textField.tag + 1
        if textField.text?.isEmpty == false,
            index < stackView.arrangedSubviews.count,
            let nextField = stackView.arrangedSubviews[index] as? UITextField {
            nextField.becomeFirstResponder()
        }
        
        let code = fields.map({ ($0 as? BackspaceableTextField)?.cachedString ?? "" })
        if code.count == stackView.arrangedSubviews.count {
            if self.isPasscodeValid?(code) ?? false {
                textField.resignFirstResponder()
            }
        }
    }
}

private class BackspaceableTextField: UITextField {
    var onBackspace: ((BackspaceableTextField, _ wasEmpty: Bool) -> Void)?
    var cachedString: String?
    var hasFocus: Bool = false {
        didSet {
            layer.borderColor = hasFocus ? UIColor.black.cgColor : UIColor.lightGray.cgColor
        }
    }
    
    override func deleteBackward() {
        let isEmpty = cachedString?.isEmpty ?? true
        super.deleteBackward()
        onBackspace?(self, isEmpty)
        cachedString = nil
    }
    
    func resizeFont() {
        if let text = self.text, let font = self.font {
            let bounds = CGRect(origin: .zero, size: self.bounds.size)
            var fontSize: CGFloat = min(self.bounds.width, self.bounds.height)
            
            for size in stride(from: fontSize, through: 0, by: -1) {
                let resizedFont = UIFont(descriptor: font.fontDescriptor, size: size)
                let frame = text.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: resizedFont], context: nil)
                if bounds.contains(frame) {
                    fontSize = size
                    break
                }
            }
            
            self.font = UIFont(descriptor: font.fontDescriptor, size: fontSize)
        }
    }
}

private class PasscodeAttemptsView: UIView {
    private let textLabel = UILabel().then {
        $0.textColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.masksToBounds = true
        self.backgroundColor = .red
        
        addSubview(textLabel)
        textLabel.snp.makeConstraints {
            $0.edges.equalTo(self.snp.edges).inset(5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAttempts(_ attempts: UInt) {
        if attempts > 0 {
            self.textLabel.text = "\(attempts) attempts left"
        }
    }
}
