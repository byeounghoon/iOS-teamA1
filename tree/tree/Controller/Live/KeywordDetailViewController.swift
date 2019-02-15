//
//  KeywordDetailViewController.swift
//  tree
//
//  Created by ParkSungJoon on 07/02/2019.
//  Copyright © 2019 gardener. All rights reserved.
//

import UIKit

class KeywordDetailViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var keywordData: TrendingSearch? {
        didSet {
            guard let keyword = keywordData?.title.query else { return }
            loadGraphData(to: keyword, startDate, endDate)
            articleData = keywordData?.articles
        }
    }
    var graphData: Graph? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    private var startDate: String {
        let oneMonth = TimeIntervalTypes.oneMonth.value
        let date = Date(timeInterval: -oneMonth, since: Date())
        return dateFormatter.string(from: date)
    }
    private var endDate: String {
        let oneDay = TimeIntervalTypes.oneDay.value
        let date = Date(timeInterval: -oneDay, since: Date())
        return dateFormatter.string(from: date)
    }
    private var articleData: [KeywordArticles]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .automatic)
            }
        }
    }
    private let timeUnit = TimeUnitTypes.week.value
    private let graphCellIdentifier = "KeywordDetailGraphCell"
    private let headerCellIdentifier = "TrendListHeaderCell"
    private let articleCellIdentifier = "KeywordDetailArticleCell"
    private let appleGothicNeoBold = "AppleSDGothicNeo-Bold"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerXIB()
        setupTableView()
        navigationBar.topItem?.title = keywordData?.title.query
    }
    
    @IBAction func backButtonItem(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func registerXIB() {
        let graphNib = UINib(nibName: graphCellIdentifier, bundle: nil)
        tableView.register(graphNib, forCellReuseIdentifier: graphCellIdentifier)
        let headerNib = UINib(nibName: headerCellIdentifier, bundle: nil)
        tableView.register(headerNib, forCellReuseIdentifier: headerCellIdentifier)
        let articleNib = UINib(nibName: articleCellIdentifier, bundle: nil)
        tableView.register(articleNib, forCellReuseIdentifier: articleCellIdentifier)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: UIScreen.main.bounds.width,
            bottom: 0,
            right: 0
        )
    }
    
    private func loadGraphData(to keyword: String, _ startDate: String, _ endDate: String) {
        let keywordGroups: [[String: Any]] = [[
            "groupName": keyword,
            "keywords": [keyword]
            ]]
        APIManager.requestGraphData(
            startDate: startDate,
            endDate: endDate,
            timeUnit: timeUnit,
            keywordGroups: keywordGroups
        ) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let graphData):
                self.graphData = graphData
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

private enum KeywordDetailSection: Int {
    case gragh
    case articleList
    
    init(section: Int) {
        switch section {
        case 0:
            self = .gragh
        default:
            self = .articleList
        }
    }
}

extension KeywordDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if articleData != nil {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch KeywordDetailSection(section: section) {
        case .gragh:
            return 1
        case .articleList:
            if let articleData = articleData {
                return articleData.count
            }
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let headerCell = tableView.dequeueReusableCell(
                withIdentifier: headerCellIdentifier
                ) as? TrendListHeaderCell else {
                    return UIView()
        }
        headerCell.headerLabel.font = UIFont(name: appleGothicNeoBold, size: 17)
        switch KeywordDetailSection(section: section) {
        case .gragh:
            headerCell.headerLabel.text = HeaderTitles.changeInteresting.rawValue
        case .articleList:
            headerCell.headerLabel.text = HeaderTitles.relatedArticles.rawValue
        }
        return headerCell.contentView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch KeywordDetailSection(section: indexPath.section) {
        case .gragh:
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: graphCellIdentifier,
                    for: indexPath
                    ) as? KeywordDetailGraphCell else {
                        fatalError(FatalErrorMessage.invalidCell.rawValue)
            }
            cell.graphData = graphData?.results.first
            return cell
        case .articleList:
            guard
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: articleCellIdentifier,
                    for: indexPath
                    ) as? KeywordDetailArticleCell else {
                        fatalError(FatalErrorMessage.invalidCell.rawValue)
            }
            if let articleData = articleData {
                cell.configure(articleData[indexPath.row])
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
