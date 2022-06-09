//
//  DataSourceManager.swift
//  DragDemo
//
//  Created by Allen long on 2022/5/16.
//

import Foundation
import HandyJSON


class DataSourceManager {
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(saveInDisk), name: UIApplication.willTerminateNotification, object: nil)
    }
    static let main = DataSourceManager()
    let mainKey = "home_main_items"
    let bottomKey = "home_bottom_items"
    
    private(set) var scrollDataSource: [[HomeItem]] = []
    
    var bottomDataSource: [HomeItem] = []
        
    func fetchFromDisk() {
        fetchMainFromDisk()
        fetchBottomFromDisk()
    }
    
    @objc func saveInDisk() {
        saveMainToDisk()
        saveBottomToDisk()
    }
    
    private func fetchMainFromDisk() {
        if let dataSourceData = UserDefaults.standard.value(forKey: mainKey) as? Data {
                guard let dataSourceJson = try? JSONSerialization.jsonObject(with: dataSourceData, options: []) as? [[[String: Any]]]
            else { return }
            var dataSource: [[HomeItem]] = []
            for sectionJson in dataSourceJson {
                var sectionDataSource: [HomeItem] = []
                for json in sectionJson {
                    if let item = HomeItem.deserialize(from: json) {
                        sectionDataSource.append(item)
                    }
                }
                dataSource.append(sectionDataSource)
            }
            scrollDataSource = dataSource
        } else {
            scrollDataSource = defaultMainItems
            saveMainToDisk()
        }
    }
    
    private func fetchBottomFromDisk() {
        if let dataSourceData = UserDefaults.standard.value(forKey: bottomKey) as? Data {
                guard let dataSourceJson = try? JSONSerialization.jsonObject(with: dataSourceData, options: []) as? [[String: Any]]
            else { return }
            var dataSource: [HomeItem] = []
            for json in dataSourceJson {
                if let item = HomeItem.deserialize(from: json) {
                    dataSource.append(item)
                }
            }
            bottomDataSource = dataSource
        } else {
            bottomDataSource = defaultBottomItems
            saveBottomToDisk()
        }
    }
    
    private func saveMainToDisk() {
        // FIXME: 便于调试，暂时关闭保存
        return
        var dataSource: [[[String: Any]]] = []
        for section in scrollDataSource {
            var jsonArr: [[String: Any]] = []
            for item in section {
                if let json = item.toJSON() {
                    jsonArr.append(json)
                }
            }
            dataSource.append(jsonArr)
        }
        if let dataSourceData = try? JSONSerialization.data(withJSONObject: dataSource, options: []) {
            UserDefaults.standard.set(dataSourceData, forKey: mainKey)
        }
    }
    
    private func saveBottomToDisk() {
        var dataSource: [[String: Any]] = []
        for item in bottomDataSource {
            if let json = item.toJSON() {
                dataSource.append(json)
            }
        }
        if let dataSourceData = try? JSONSerialization.data(withJSONObject: dataSource, options: []) {
            UserDefaults.standard.set(dataSourceData, forKey: bottomKey)
        }
    }
    
    func updateScrollItems(_ items: [HomeItem], at index: Int) {
        let dataSourceCount = scrollDataSource.count
        if dataSourceCount == index {
            DataSourceManager.main.scrollDataSource.append(items)
        } else if dataSourceCount > index {
            scrollDataSource[index] = items
        } else {
            fatalError()
        }
    }
    
    // TODO: 关闭编辑模式时调用，需要清除掉scrollDataSource中item数量为空的页面
    func homeEndEdit() {
        NotificationCenter.default.post(name: .homeDataSourceUpdated, object: nil)
    }
}

let defaultMainItems: [[HomeItem]] = [
    [
        HomeItem(title: "QQ"),
        HomeItem(title: "微信"),
        HomeItem(title: "支付宝"),
        HomeItem(title: "淘宝"),
        HomeItem(title: "追书神器"),
    ],
    [
        HomeItem(title: "微博"),
        HomeItem(title: "百度"),
        HomeItem(title: "QQ音乐"),
        HomeItem(title: "网易云音乐"),
        HomeItem(title: "哔哩哔哩"),
        HomeItem(title: "皮皮虾"),
        HomeItem(title: "美团"),        
    ]
]

let defaultBottomItems: [HomeItem] = [
    HomeItem(title: "snapChat"),
    HomeItem(title: "facebook"),
    HomeItem(title: "google"),
]


class HomeItem: HandyJSON {
    
    required init() {}
    
    var title: String = ""
    
    init(title: String) {
        self.title = title
    }
}

//enum HomeItemLocationType {
//    case scrollView
//    case bottom
//}
//
//struct HomeItemLocation {
//    var scrollVCIndex: Int = 0
//    var type: HomeItemLocationType = .scrollView
//    var indexPath: IndexPath = IndexPath(item: 0, section: 0)
//
//}


