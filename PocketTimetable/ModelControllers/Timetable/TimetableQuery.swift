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

/// A model encapsulating a query for the timetable API
public struct TimetableQuery: ExpressibleByStringLiteral {

    // MARK: Properties

    /// The station name to fetch
    public var stationName: String
    /// The date serving as time anchor
    public var date: Date?
    /// The time anchor mode
    public var mode: Mode
    /// If `true` platforms will be returned when present
    public var showPlatforms: Bool
    /// The max number of result returned
    public var limit: Int?

    /// Build a query from the given station name
    /// - Parameter value: The station name
    public init(stringLiteral value: String) {
        self.init(stationName: value)
    }

    /// Initialize a timetable query
    /// - Parameters:
    ///   - stationName: The station name to fetch.
    ///   - date: The date serving as time anchor. Defaults to `now`. If `nil` is passed the current time is used.
    ///   - mode: The time anchor mode. Defaults to `departure`.
    ///   - showPlatforms: If `true` platforms will be returned when present. Defaults to `false`.
    ///   - limit: The max number of result returned. If `nil` all connection within 24h will be returned. Defaults to `nil`.
    public init(stationName: String, date: Date? = nil, mode: Mode = .departure, showPlatforms: Bool = false, limit: Int? = nil) {
        self.stationName = stationName
        self.date = date
        self.mode = mode
        self.showPlatforms = showPlatforms
        self.limit = limit
    }
}

// MARK: Helper Strucs

extension TimetableQuery {
    /// The mode of the query
    public enum Mode {
        /// Departure
        case departure
        /// Arrival
        case arrival
    }
}
