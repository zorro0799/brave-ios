// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveUI
import Storage

struct FeedCard2 {
    enum VerticalGroupViewStyle {
        case `default`
        case branded
        case numbered
    }
    enum Kind {
        case headline
        case smallHeadline
        case verticalGroup(title: String? = nil, style: VerticalGroupViewStyle = .default)
        case horizontalGroup(title: String? = nil)
    }
    var kind: Kind
    var items: [FeedItem]
}

/// Displays a list of feeds from the Brave Today list
class BraveTodayViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    let layout = UICollectionViewFlowLayout()
    let collectionView: UICollectionView
    
    private var cards: [FeedCard2] = [
        .init(kind: .headline, items: [])
    ]
    
    init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        collectionView.register(FeedCardCell<HeadlineCardView>.self)
        collectionView.register(FeedCardCell<SmallHeadlineFeedView>.self)
        collectionView.register(FeedCardCell<VerticalFeedGroupView>.self)
        collectionView.register(FeedCardCell<HorizontalFeedGroupView>.self)
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
    }
    
    let dateFormatter = DateFormatter().then {
        $0.timeStyle = .short
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = cards[indexPath.item]
        switch card.kind {
        case .headline:
            let cell = collectionView.dequeueReusableCell(for: indexPath) as FeedCardCell<HeadlineCardView>
            let feed = card.items[0]
            cell.view.feedView.titleLabel.text = feed.title
            cell.view.feedView.dateLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(feed.publishTime)))
            return cell
        default:
            break
        }
        assertionFailure("[BraveToday] Somehow ended up with no card type: \(card)")
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = view.bounds.width - (layout.sectionInset.left + layout.sectionInset.right)
        if case .smallHeadline = cards[indexPath.item].kind {
            // Small headline only takes up half the space
            return CGSize(width: floor(availableWidth / 2.0) - floor(layout.minimumInteritemSpacing / 2.0), height: 400)
        }
        return CGSize(width: availableWidth, height: 400)
    }
}
