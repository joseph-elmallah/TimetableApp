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

/// The data source of the timetable view controller table view
final class TimetableTableViewDiffableDataSource: UITableViewDiffableDataSource<Date, TimetableConnectionModel> {
    private lazy var sectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Build a data source linked to the given table view.
    ///
    /// This data source will take care of registering the correct cells and sections
    /// 
    /// - Parameter tableView: The table view in need of a data source
    init(tableView: UITableView) {
        tableView.register(TimetableConnectionCell.self, forCellReuseIdentifier: TimetableConnectionCell.identifier)

        super.init(tableView: tableView) { (tableView, indexPath, connection) -> UITableViewCell? in
            let cell: TimetableConnectionCell = tableView
                .dequeueReusableCell(
                    withIdentifier: TimetableConnectionCell.identifier,
                    for: indexPath) as! TimetableConnectionCell
            cell.populate(using: connection)
            return cell
        }
        defaultRowAnimation = .top
    }

    /// Update the data source with the given new data
    /// - Parameters:
    ///   - connectionsGroupedByDay: The connections to use for the update
    ///   - tableView: All visible cells of the table view will have their countdown updated
    func apply(connectionsGroupedByDay: TimetableConnectionsGroupedByDay, refresh tableView: UITableView) {
        var snapshot = NSDiffableDataSourceSnapshot<Date, TimetableConnectionModel>()
        for section in connectionsGroupedByDay {
            snapshot.appendSections([section.date])
            snapshot.appendItems(section.connections)
        }
        apply(snapshot, animatingDifferences: true) {
            tableView.indexPathsForVisibleRows?.forEach({ (indexPath) in
                let connection = connectionsGroupedByDay[indexPath.section].connections[indexPath.row]
                let cell = tableView.cellForRow(at: indexPath) as! TimetableConnectionCell
                cell.updateCountdown(using: connection)
            })
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dateOfSection = self.snapshot().sectionIdentifiers[section]
        if Calendar.current.isDateInToday(dateOfSection) {
            // No section header if it's same day
            return nil
        } else {
            return sectionDateFormatter.string(from: dateOfSection)
        }
    }
}
