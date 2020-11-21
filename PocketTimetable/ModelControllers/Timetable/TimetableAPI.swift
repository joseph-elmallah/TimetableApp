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

/// The timetable API builder
enum TimetableAPI {

    // MARK: Main functions

    /// Builds a request destined for the timetable API
    /// - Parameters:
    ///   - query: The query to execute
    ///   - environment: The environment to use
    /// - Throws: `PTError` in case of networking or parsing errors
    /// - Returns: A `URLRequest` configured with the query and environment
    static func stationboard(query: TimetableQuery, environment: Environment) throws -> URLRequest {
        let queryItems = self.queryItems(from: query)
        let endpointURL = try NetworkingHelper.createEndpointURL(withPath: "stationboard.json", queryItems: queryItems, environment: environment)
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "GET"
        return request
    }

    // MARK: Helper Methods

    /// A formatted for the request date
    private static let requestDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    /// A formatted for the request time
    private static let requestTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    /// Convert a query into a list of `URLQueryItem` to set in the request
    /// - Parameter query: The query to map
    /// - Returns: A mapped list of `URLQueryItem` from the passed query
    private static func queryItems(from query: TimetableQuery) -> [URLQueryItem] {
        var queryItems = [
            URLQueryItem(name: "stop", value: query.stationName),
            URLQueryItem(name: "show_delays", value: true.timetableRequestFormat),
            URLQueryItem(name: "show_tracks", value: query.showPlatforms.timetableRequestFormat),
            URLQueryItem(name: "show_trackchanges", value: query.showPlatforms.timetableRequestFormat),
            URLQueryItem(name: "mode", value: query.mode.timetableRequestFormat),
        ]
        if let limit = query.limit {
            queryItems.append(
                URLQueryItem(name: "limit", value: String(describing: limit))
            )
        }
        if let date = query.date {
            let dateValue = requestDateFormatter.string(from: date)
            let timeValue = requestTimeFormatter.string(from: date)
            queryItems.append(contentsOf: [
                URLQueryItem(name: "date", value: dateValue),
                URLQueryItem(name: "time", value: timeValue)
            ])
        }
        return queryItems
    }
}

// MARK: Helper Extensions

private extension Bool {
    /// Map a `boolean` into a string for the `TimetableAPI` request
    var timetableRequestFormat: String {
        self ? "1" : "0"
    }
}

private extension TimetableQuery.Mode {
    /// Map a `TimetableQuery.Mode` into a string for the `TimetableAPI` request
    var timetableRequestFormat: String {
        switch self {
            case .arrival:
                return "arrival"
            case .departure:
                return "depart"
        }
    }
}
