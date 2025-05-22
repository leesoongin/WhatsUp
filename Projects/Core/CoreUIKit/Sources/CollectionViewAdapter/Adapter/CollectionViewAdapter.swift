//
//  CollectionViewAdapter.swift
//  AlamofirePractice
//
//  Created by 이숭인 on 6/11/24.
//

import UIKit
import Combine
import CombineCocoa
import SnapKit

public final class CollectionViewAdapter: NSObject {
    var cancellables = Set<AnyCancellable>()
    
    weak var collectionView: UICollectionView?
    private var collectionViewLayoutKey: UInt8 = 0
    
    /// Stategy 의 Adaptive size 계산을 위함
    let viewControllerForSnapshot = UIViewController()
    
    var dataSource: UICollectionViewDiffableDataSource<SectionItem, ListItem>!
    var registeredCellIdentifiers = Set<String>()
    var registeredSupplementaryCellIdentifiers = Set<String>()
    var sizeCache: [String: CGSize] = [:]
    
    private var lineSpacingForSectionAt: CGFloat = .zero
    private var itemSpacingForSectionAt: CGFloat = .zero
    private var isAnimationEnabled: Bool = false
    
    private let didSelectItemSubject = PassthroughSubject<ItemModelType, Never>()
    public var didSelectItemPublisher: AnyPublisher<ItemModelType, Never> {
        didSelectItemSubject.eraseToAnyPublisher()
    }
    
    private let willDisplayCellSubject = PassthroughSubject<IndexPath, Never>()
    public var willDisplayCellPublisher: AnyPublisher<IndexPath, Never> {
        willDisplayCellSubject.eraseToAnyPublisher()
    }
    
    private let willDisplayCellIdentifierSubject = PassthroughSubject<String, Never>()
    public var willDisplayCellIdentifierPublisher: AnyPublisher<String, Never> {
        willDisplayCellIdentifierSubject.eraseToAnyPublisher()
    }
    
    private let visibleItemSubject = PassthroughSubject<IndexPath, Never>()
    public var visibleItemPublisher: AnyPublisher<IndexPath, Never> {
        visibleItemSubject.eraseToAnyPublisher()
    }
    
    private let didScrollSubject = PassthroughSubject<(visibleItems: [NSCollectionLayoutVisibleItem], contentOffset: CGPoint), Never>()
    public var didScrollPublisher: AnyPublisher<(visibleItems: [NSCollectionLayoutVisibleItem], contentOffset: CGPoint), Never> {
        didScrollSubject.eraseToAnyPublisher()
    }
    
    private let actionEventSubject = PassthroughSubject<ActionEventItem, Never>()
    public var actionEventPublisher: AnyPublisher<ActionEventItem, Never> {
        actionEventSubject.eraseToAnyPublisher()
    }
    
    private let inputSectionSubject = CurrentValueSubject<[SectionModelType], Never>([])
    private var sections: [SectionModelType] {
        inputSectionSubject.value
    }
    
    private let reloadFinishSubject = PassthroughSubject<Void, Never>()
    public var reloadFinishPublisher: AnyPublisher<Void, Never> {
        reloadFinishSubject.eraseToAnyPublisher()
    }
    
    public init(
        with collectionView: UICollectionView,
        lineSpacingForSectionAt: CGFloat = .zero,
        itemSpacingForSectionAt: CGFloat = .zero,
        isAnimationEnabled: Bool = false
    ) {
        super.init()
        
        self.collectionView = collectionView
        self.collectionView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.collectionView?.delegate = self
        
        self.lineSpacingForSectionAt = lineSpacingForSectionAt
        self.itemSpacingForSectionAt = itemSpacingForSectionAt
        self.isAnimationEnabled = isAnimationEnabled
        
        setupCollectionDataSource()
        bindInputSections()
        bindDelegateEvent()
    }
    
    public func pinToVisibleBoundsSectionHeader() {
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionHeadersPinToVisibleBounds = true
            layout.sectionInsetReference = .fromSafeArea
        }
    }
    
    public func pinToVisibleBoundsSectionFooter() {
        if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionFootersPinToVisibleBounds = true
            layout.sectionInsetReference = .fromSafeArea
        }
    }
    
    // 스크롤 방향을 변경하는 메서드
    public func toggleScrollDirection() {
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            // 현재 방향에 따라 새로운 방향 설정
            flowLayout.scrollDirection = .horizontal
        }
    }
}

//MARK: - CollectionView Action & Data Binding
extension CollectionViewAdapter {
    /// Data Binding
    private func setupCollectionDataSource() {
        guard let collectionView = collectionView else { return }
        
        dataSource = UICollectionViewDiffableDataSource<SectionItem, ListItem>(collectionView: collectionView) { [weak self] (collectionView, indexPath, dj) -> UICollectionViewCell? in
            guard let self else {
                return nil
            }
            
            guard let itemModel = self.itemModel(at: indexPath) else {
                return nil
            }
            
            //regist
            let reuseIdentifier = itemModel.viewType.getIdentifier()
            self.registerCellIfNeeded(with: itemModel)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            self.bindItemModelIfNeeded(to: cell, with: itemModel)
            self.bindActionEvent(with: cell)
            
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] (view, kind, indexPath) -> UICollectionReusableView? in
            guard let self else {
                return nil
            }
            
            guard let itemModel = self.headerFooterOfItemModel(at: indexPath, kind: kind) else {
                return nil
            }
            
            self.registerSupplementaryViewIfNeeded(with: itemModel, kind: kind)
            
            let reuseIdentifier = itemModel.viewType.getIdentifier()
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseIdentifier, for: indexPath)
            
            self.bindItemModelIfNeeded(to: cell, with: itemModel)
            self.bindActionEvent(with: cell)
            return cell
        }
    }
    
    /// Action Binding
    func setupInputSectionsIfNeeded(with sections: [SectionModelType]) {
        inputSectionSubject.send(sections)
    }
    
    private func bindInputSections() {
        inputSectionSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                self?.updateSections(with: sections)
            }
            .store(in: &cancellables)
    }
    
    private func updateSections(with inputSections: [SectionModelType]) {
        guard !inputSections.isEmpty else { return }
        
        applySnapshot(with: inputSections)
    }
    
    private func applySnapshot(with sections: [SectionModelType]) {
        var snapshot = NSDiffableDataSourceSnapshot<SectionItem, ListItem>()
        
        sections.forEach { section in
            let sectionItem = SectionItem(sectionModel: section)
            let listItems = section.itemModels.map { ListItem(itemModel: $0) }
            
            snapshot.appendSections([sectionItem])
            snapshot.appendItems(listItems, toSection: sectionItem)
        }
        
        self.dataSource.apply(snapshot, animatingDifferences: isAnimationEnabled)
        self.reloadFinishSubject.send(())
    }
    
    private func bindDelegateEvent() {
        // do something
    }
    
    private func cancelForPrepareForReuse(with view: UICollectionReusableView, cellCancellables: [AnyCancellable]) {
        view.prepareForReuseSubject
            .first()
            .sink { _ in
                cellCancellables.forEach { $0.cancel() }
            }
            .store(in: &cancellables)
    }
}

//MARK: - Cell DataBinding && ActionBinding && Regist
extension CollectionViewAdapter {
    private func bindActionEvent(with view: UICollectionReusableView) {
        guard let actionEventEmitable: ActionEventEmitable = convertProtocol(with: view) else { return }
        
        let actionEventCancellables = actionEventEmitable.actionEventEmitter
            .sink { [weak self] actionEvent in
                self?.actionEventSubject.send(actionEvent)
            }
        actionEventCancellables
            .store(in: &cancellables)
        
        cancelForPrepareForReuse(with: view, cellCancellables: [actionEventCancellables])
    }
    
    fileprivate func bindItemModelIfNeeded(to cell: UICollectionReusableView, with itemModel: ItemModelType) {
        guard let cell = cell as? ItemModelBindableProtocol else { return }
        UIView.performWithoutAnimation {
            cell.bind(with: itemModel)
        }
    }
    
    private func registerCellIfNeeded(with itemModel: ItemModelType) {
        let reuseIdentifier = itemModel.viewType.getIdentifier()
        guard registeredCellIdentifiers.contains(reuseIdentifier) == false else { return }
        
        collectionView?.register(itemModel.viewType.getClass(), forCellWithReuseIdentifier: reuseIdentifier)
        registeredCellIdentifiers.insert(reuseIdentifier)
    }
    
    private func registerSupplementaryViewIfNeeded(with itemModel: ItemModelType, kind: String) {
        let reuseIdentifier = itemModel.viewType.getIdentifier()
        guard registeredSupplementaryCellIdentifiers.contains("\(kind)-\(reuseIdentifier)") == false else {
//            print("::: 이미있음")
            return
        }
        
//        print("::: 저장함")
        collectionView?.register(itemModel.viewType.getClass(), forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
        registeredSupplementaryCellIdentifiers.insert("\(kind)-\(reuseIdentifier)")
    }
}

//MARK: - Finder
extension CollectionViewAdapter {
    func itemModel(at indexPath: IndexPath) -> ItemModelType? {
        sections[safe: indexPath.section]?.itemModels[safe: indexPath.item]
    }
    
    func headerFooterOfItemModel(at indexPath: IndexPath, kind: String) -> ItemModelType? {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
//            print("::: header return")
            return sections[safe: indexPath.section]?.header
        case UICollectionView.elementKindSectionFooter:
//            print("::: footer return")
            return sections[safe: indexPath.section]?.header
        default:
            return nil
        }
    }
    
    func findIndexPathByIdentifier(with identifier: String) -> IndexPath? {
        var target: IndexPath? = nil
        sections.enumerated().forEach { index, section in
            if let row = section.itemModels.firstIndex(where: { $0.identifier == identifier }) {
                target = IndexPath(item: row, section: index)
            }
        }
        
        return target
    }
    
    func convertProtocol<P>(with view: UICollectionReusableView) -> P? {
        if let cell = view as? UICollectionViewCell,
           let target = (cell as? P) ?? cell.contentView.subviews.first as? P {
            return target
        } else {
            return nil
        }
    }
}

extension CollectionViewAdapter: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let sectionModel = sections[safe: indexPath.section],
              let itemModel = self.itemModel(at: indexPath) else {
            return .zero
        }
        registerCellIfNeeded(with: itemModel)
        
        return getCachedSize(section: sectionModel, item: itemModel)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let section = sections[safe: section], let header = section.header else { return .zero }

        return getCachedSize(section: section, item: header)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let section = sections[safe: section], let footer = section.footer else { return .zero }

        return getCachedSize(section: section, item: footer)
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacingForSectionAt
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return itemSpacingForSectionAt
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let itemModel = itemModel(at: indexPath) else {
            return
        }
        
        didSelectItemSubject.send(itemModel)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        willDisplayCellSubject.send(indexPath)

        if let identifierFromWillDisplayCell = sections[safe: indexPath.section]?.itemModels[safe: indexPath.row]?.identifier {
            willDisplayCellIdentifierSubject.send(identifierFromWillDisplayCell)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let itemModel = itemModel(at: indexPath) else {
            return
        }
    }
    
    private func getCachedSize(section: SectionModelType, item: ItemModelType) -> CGSize {
        guard sizeCache["\(section.sizeHashValue)_\(item.sizeHashValue)"] == nil else {
            return sizeCache["\(section.sizeHashValue)_\(item.sizeHashValue)"] ?? CGSize(width: 0, height: 0)
        }
        

        let width = calculateWidthStrategyValue(sectionModel: section, itemModel: item)
        let height = calculateHeightStrategyValue(itemModel: item, width: width)
        
        let calculatedSize = CGSize(width: width, height: height)
        sizeCache["\(section.sizeHashValue)_\(item.sizeHashValue)"] = calculatedSize
//        print("::: calculatedSize > \(calculatedSize)")
        return calculatedSize
    }
    
    private func calculateWidthStrategyValue(sectionModel: SectionModelType, itemModel: ItemModelType) -> CGFloat {
        guard let collectionView = collectionView else { return .leastNonzeroMagnitude }
        let baseWidth = collectionView.bounds.width

        // static과 ratio는 inset 계산이 필요 없어보인다
        switch itemModel.widthStrategy {
        case .static(let value):
            return value
        case .fill:
            return baseWidth
        case .column(let count):
            return floor((baseWidth) / CGFloat(count))
        case .ratioWithCollectionView(let ratio):
            return floor(baseWidth / ratio)
        case .adaptive:
            return calculateAdaptiveWidth(at: itemModel)
        }
    }
        
    private func calculateHeightStrategyValue(itemModel: ItemModelType, width: CGFloat) -> CGFloat {
        guard let collectionView = collectionView else { return .leastNonzeroMagnitude }
        let baseHeight = collectionView.bounds.height
        
        switch itemModel.heightStrategy {
        case .static(let value):
            return value
        case .ratio(let ratio):
            return floor(width * ratio)
        case .ratioWithCollectionView(let ratio):
            return floor(baseHeight * ratio)
        case .adaptive:
            return calculateAdaptiveHeight(at: itemModel, width: width)
        }
    }
    
    private func calculateAdaptiveWidth(at itemModel: ItemModelType) -> CGFloat {
        // 셀 초기화. 기존에 붙어있는 셀을 재활용. 없으면 생성
        let dummyView = createDummyViewIfNeeded(at: itemModel)

        // model을 바인딩하여 크기를 제대로 잡아준다
        dummyView.bind(with: itemModel)
        
        let targetSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: .zero)
        // 스냅샷을 통해 셀의 크기를 계산합니다.
        let fittingSize = dummyView.contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel, // 너비는 셀의 내용에 따라 동적으로 조정
            verticalFittingPriority: .required // 높이는 고정된 값으로 설정
        )
        
        return fittingSize.width
    }
    
    private func calculateAdaptiveHeight(at itemModel: ItemModelType, width: CGFloat) -> CGFloat {
        // 셀 초기화. 기존에 붙어있는 셀을 재활용. 없으면 생성
        let dummyView = createDummyViewIfNeeded(at: itemModel, with: width)

        // model을 바인딩하여 크기를 제대로 잡아준다
        dummyView.bind(with: itemModel)

        
        let targetSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        // 4. 스냅샷을 통해 셀의 크기를 계산합니다.
        let fittingSize = dummyView.contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required, // 너비는 고정된 값으로 설정
            verticalFittingPriority: .fittingSizeLevel // 높이는 셀의 내용에 따라 동적으로 조정
        )
        
        return fittingSize.height
    }
    
    private func createDummyViewIfNeeded(at itemModel: ItemModelType, with width: CGFloat? = nil) -> ItemModelBindable {
        guard case let .type(viewType) = itemModel.viewType else {
            fatalError()
        }
        
        return viewType.init(frame: .zero)
    }
}
