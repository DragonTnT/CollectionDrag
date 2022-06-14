//
//  BottomVC.swift
//  NewDragDemo
//
//  Created by Allen long on 2022/5/19.
//

import UIKit

class BottomVC: BaseDragViewController {
    override func setupUI() {
        super.setupUI()
        collectionView.backgroundColor = .lightGray.withAlphaComponent(0.3)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    override func saveItemsToManager() {
//        DataSourceManager.main.bottomDataSource = items
    }
    override func changePositonForCallBack(position: CGPoint) -> CGPoint {
        return CGPoint(x: position.x, y: position.y + kScreenH - adapter(120))
    }
}
