// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import IntentsUI
import SnapKit
import Shared
import CoreData
import Data

extension History {
    static func getFetchRequest() -> NSFetchRequest<History> {
        var selfName = String(describing: self)
        
        // This is a hack until FaviconMO won't be renamed to Favicon.
        if selfName.contains("FaviconMO") {
            selfName = "Favicon"
        }
        
        return NSFetchRequest<History>(entityName: selfName)
    }
    
    static func all(where predicate: NSPredicate? = nil,
                    sortDescriptors: [NSSortDescriptor]? = nil,
                    fetchLimit: Int = 0,
                    context: NSManagedObjectContext = DataController.viewContext) -> [History]? {
        let request = getFetchRequest()
        
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Fetch error: \(error)")
        }
        
        return nil
    }
}

class IntentViewController: UIViewController, INUIHostedViewControlling {

    private var itemsPerRow: CGFloat = 1

    private var dataSource = [History]()
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = History.all() ?? []
        
        
        let fetchRequest = NSFetchRequest<History>()
        let context = DataController.viewContext
        
        fetchRequest.entity = History.entity()
        fetchRequest.fetchBatchSize = 20
        fetchRequest.fetchLimit = 200
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "visitedOn", ascending: false)]
        dataSource = try! context.fetch(fetchRequest)

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
            let endpointString = intent.anything else {
                completion(true, parameters, self.desiredSize)
                return
        }
        
        //self.dataSource = History.frc().fetchedObjects ?? []
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
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookmark", for: indexPath) as? GenericCell<BookmarksView> else {

            return UICollectionViewCell()
        }

        cell.view.history = self.dataSource[indexPath.row]
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

            return CGSize(width: floor(width / itemsPerRow), height: 150.0)
        }
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
    }
}

private class BookmarksView: UIView {
    public var history: History? {
        didSet {
            self.titleLabel.text = history?.title
            self.infoLabel.text = "History"
            self.urlLabel.text = "\(history?.url ?? "N/A")"
        }
    }

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillProportionally
    }

    private let imageStackView = UIStackView().then {
        $0.spacing = 14.0
        $0.alignment = .center
    }
    
    private let detailsStackView = UIStackView().then {
        $0.axis = .vertical
    }

    private let titleBackground = UIView().then {
        $0.backgroundColor = .lightGray
    }

    private let titleLabel = UILabel().then {
        $0.text = "Bookmark"
        $0.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        $0.textColor = .white
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = UIImage(named: "browser_lock_popup")?.withAlignmentRectInsets(UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
        $0.setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    private let infoLabel = UILabel().then {
        $0.text = "Type: History"
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
    }
    
    private let urlLabel = UILabel().then {
        $0.text = "URL: Some Sample Text"
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 13.0)
    }
    
    private let spacer = UIView().then {
        $0.setContentHuggingPriority(.defaultLow, for: .vertical)
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 5.0
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor(white: 0.25, alpha: 0.1)

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        titleBackground.addSubview(titleLabel)
        
        stackView.addArrangedSubview(titleBackground)
        stackView.addArrangedSubview(imageStackView)
        stackView.addArrangedSubview(spacer)
        
        imageStackView.addArrangedSubview(imageView)
        imageStackView.addArrangedSubview(detailsStackView)
        detailsStackView.addArrangedSubview(UIView())
        detailsStackView.addArrangedSubview(infoLabel)
        detailsStackView.addArrangedSubview(urlLabel)
        detailsStackView.addArrangedSubview(UIView())

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.width.height.equalTo(64.0)
        }

        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(5.0)
            $0.height.equalTo(25.0)
        }
        
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
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
