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

/// A wrapper for displaying `TimetableConnectionView` in a table
final class TimetableConnectionCell: UITableViewCell {

    // MARK: Properties

    /// The cell identifier
    static let identifier = String(describing: TimetableConnectionCell.self)

    // MARK: Subviews

    /// The wrapped view
    private let timetableConnectionView = TimetableConnectionView()

    // MARK: Initializers

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(timetableConnectionView)
        timetableConnectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timetableConnectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            timetableConnectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            timetableConnectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            timetableConnectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Accessors

    /// Use the passed model to  configure the content of the cell
    /// - Parameter connection: The connection to use a model
    func populate(using connection: TimetableConnectionModel) {
        timetableConnectionView.line = TimetableConnectionView.LineModel(
            name: connection.line,
            foregroundColorHex: connection.foregroundColorCode,
            backgroundColorHex: connection.backgroundColorCode
        )

        timetableConnectionView.destination = connection.terminal.name

        if let track = connection.platform {
            timetableConnectionView.setPlatform("platform \(track)", hasChanges: connection.hasPlatformChange)
        }

        updateCountdown(using: connection)
    }

    /// Update the counter value of the cell using the given model
    /// - Parameter connection: The model to use for the update
    func updateCountdown(using connection: TimetableConnectionModel) {
        timetableConnectionView.setCountdown(departureDate: connection.departureDate, delay: connection.departureDelay)
    }
}
