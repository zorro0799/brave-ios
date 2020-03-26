// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Storage
import BraveUI

/// Defines the basic feed card cell. A feed card can display 1 or more feed
/// items. This cell is defined by the `View` type
class FeedCardCell<View: UIView>: UICollectionViewCell, CollectionViewReusable {
    var view = View()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(view)
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}

class HeadlineCardView: CardBackgroundButton {
    let feedView = FeedItemView(layout: .brandedHeadline).then {
        // Title label slightly different
        $0.titleLabel.font = .systemFont(ofSize: 18.0, weight: .semibold)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(feedView)
        feedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

class SmallHeadlineFeedView: HeadlineCardView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        feedView.titleLabel.numberOfLines = 4
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }
}

/// A group of feed items placed horizontally in a card
class HorizontalFeedGroupView: FeedGroupView {
    init() {
        super.init(axis: .horizontal, feedLayout: .horizontal)
    }
}

/// A group of feed items placed vertically in a card
class VerticalFeedGroupView: FeedGroupView {
    init() {
        super.init(axis: .vertical, feedLayout: .vertical)
    }
}

/// A group of feed items numbered and placed vertically in a card
class NumberedFeedGroupView: FeedGroupView {
    init() {
        super.init(axis: .vertical, feedLayout: .verticalNoImage, transformItems: { views in
            // Turn the usual feed group item into a numbered item
            views.enumerated().map { view in
                UIStackView().then {
                    $0.spacing = 16
                    $0.alignment = .center
                    $0.addStackViewItems(
                        .view(UILabel().then {
                            $0.text = "\(view.offset + 1)"
                            $0.font = .systemFont(ofSize: 16, weight: .bold)
                            $0.appearanceTextColor = UIColor(white: 1.0, alpha: 0.4)
                        }),
                        .view(view.element)
                    )
                }
            }
        })
    }
}
