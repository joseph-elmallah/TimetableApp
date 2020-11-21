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

import Foundation

typealias TimetableConnectionsGroupedByDay = [(date: Date, connections: [TimetableConnectionModel])]

/// A Helper to format timetable connection data from plain connections into connections grouped by same day
enum TimetableViewControllerDataFormatter {

    /// Removes duplicated values
    /// - Parameter array: the array to clean
    /// - Returns: the clean array with unique values
    static func removeDuplicates(from array: [TimetableConnectionModel]?) -> [TimetableConnectionModel]? {
        guard let array = array else {
            return nil
        }
        guard var previous = array.first else {
            return array
        }

        var cleanArray: [TimetableConnectionModel] = []
        for index in 1..<array.count {
            let current = array[index]
            if previous != current {
                cleanArray.append(current)
            }
            previous = current
        }

        return cleanArray
    }

    /// Groups the response connection by day
    /// - Parameter timetableResponseModel: The response model
    /// - Returns: Connections grouped by day
    static func groupConnectionsByDay(response timetableResponseModel: TimetableResponseModel?) -> TimetableConnectionsGroupedByDay {
        guard let connections = timetableResponseModel?.connections,
              let firstConnection = connections.first else {
            return []
        }

        let calendar = Calendar.current

        var connectionsGroupedByDay: TimetableConnectionsGroupedByDay = []
        var currentDay: Date = calendar.startOfDay(for: firstConnection.departureDate)
        var currentDayGroup: [TimetableConnectionModel] = []

        for connection in connections {
            if calendar.isDate(connection.departureDate, inSameDayAs: currentDay) {
                currentDayGroup.append(connection)
            } else {
                connectionsGroupedByDay.append((currentDay, currentDayGroup))
                currentDay = calendar.startOfDay(for: connection.departureDate)
                currentDayGroup = [connection]
            }
        }
        connectionsGroupedByDay.append((currentDay, currentDayGroup))
        return connectionsGroupedByDay
    }

}
