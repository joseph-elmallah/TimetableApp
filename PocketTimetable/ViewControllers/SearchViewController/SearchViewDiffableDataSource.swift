//
// MIT License
// 
// Copyright (c) 2020 Joseph El Mallah
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

final class SearchViewDiffableDataSource: UITableViewDiffableDataSource<Int, SearchResultModel> {

    /// Build a data source linked to the given table view.
    ///
    /// This data source will take care of registering the correct cells and sections
    ///
    /// - Parameter tableView: The table view in need of a data source
    init(tableView: UITableView) {
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.identifier)

        super.init(tableView: tableView) { (tableView, indexPath, connection) -> UITableViewCell? in
            let cell: SearchResultCell = tableView
                .dequeueReusableCell(
                    withIdentifier: SearchResultCell.identifier,
                    for: indexPath) as! SearchResultCell
            cell.populate(using: connection)
            return cell
        }
        defaultRowAnimation = .top
    }

    /// Update the data source with the given new data
    /// - Parameters:
    ///   - connectionsGroupedByDay: The connections to use for the update
    ///   - tableView: All visible cells of the table view will have their countdown updated
    func apply(searchResults: [SearchResultModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SearchResultModel>()
        snapshot.appendSections([0])
        snapshot.appendItems(searchResults)
        apply(snapshot, animatingDifferences: true)
    }

}
