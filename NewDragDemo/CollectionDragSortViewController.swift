//
//  CollectionDragSortViewController.swift
//  DemosInSwift
//
//  Created by 古创 on 2021/9/9.
//  Copyright © 2021 c. All rights reserved.
//

import UIKit

class CollectionDragSortViewController: BaseDragViewController {
    
    var scrollDataSourceIndex: Int
    
    init(dataSourceIndex: Int, items: [HomeItem]) {
        self.scrollDataSourceIndex = dataSourceIndex
        super.init(items: items)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        super.setupUI()
        // TODO: 查看非刘海屏，48的设置是否合理
        collectionView.contentInset = UIEdgeInsets(top: 48, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = .clear
        collectionView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(-120)
        }
    }
    
    override func homeSaveItemsToManager() {
        DataSourceManager.main.updateScrollItems(items, at: scrollDataSourceIndex)
    }
    
}
