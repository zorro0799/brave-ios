// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import IntentsUI
import SnapKit
import Shared
import CoreData
import Data

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    private var itemsPerRow: CGFloat = 1
    
    private var bookmarks = [Bookmark]()
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = 15.0
        flowLayout.minimumLineSpacing = 15.0
        flowLayout.invalidateLayout()
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delaysContentTouches = false
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(GenericCell<BookmarksView>.self, forCellWithReuseIdentifier: "bookmark")
    }
        
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {

        guard let intent  = interaction.intent as? SearchIntent,
            let endpointString = intent.endpoint else {
                completion(true, parameters, self.desiredSize)
                return
        }
        
        let frc = Bookmark.foldersFrc(excludedFolder: nil)
        self.bookmarks = frc.fetchedObjects ?? []
        self.collectionView.reloadData()
        completion(true, parameters, self.desiredSize)
    }
    
    var desiredSize: CGSize {
        return self.extensionContext!.hostedViewMaximumAllowedSize
    }
    
}

extension IntentViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookmark", for: indexPath) as? GenericCell<BookmarksView> else {
            
            return UICollectionViewCell()
        }
        
        cell.view.bookmark = self.bookmarks[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "default", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSpacing: CGFloat = 15.0
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let insets = self.collectionView(collectionView, layout: layout, insetForSectionAt: indexPath.section)
            var width = collectionView.bounds.width - itemSpacing * (itemsPerRow - 1)
            width -= insets.left + insets.right
            
            return CGSize(width: floor(width / itemsPerRow), height: 175.0)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    }
}

private class BookmarksView: UIView {
    public var bookmark: Bookmark? {
        didSet {
            self.titleLabel.text = bookmark?.displayTitle
            self.infoLabel.text = bookmark?.url
        }
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .vertical
    }
    
    private let imageStackView = UIStackView().then {
        $0.spacing = 12.0
    }
    
    private let titleBackground = UIView().then {
        $0.backgroundColor = .lightGray
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "Bookmark"
    }
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let infoLabel = UILabel().then {
        $0.text = "Some Sample Text"
        $0.numberOfLines = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        stackView.addArrangedSubview(titleBackground)
        stackView.addArrangedSubview(imageStackView)
        imageStackView.addArrangedSubview(imageView)
        imageStackView.addArrangedSubview(infoLabel)
        titleBackground.addSubview(titleLabel)
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(64.0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(5.0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class GenericCell<View: UIView>: UICollectionViewCell {
    public let view = View()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.view)
        self.contentView.preservesSuperviewLayoutMargins = false
        self.contentView.layoutMargins = .zero
        
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
