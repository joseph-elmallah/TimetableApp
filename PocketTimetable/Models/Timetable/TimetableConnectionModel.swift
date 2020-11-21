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

/// A model describing a connection from a timetable request
public struct TimetableConnectionModel: Decodable, Hashable {

    // MARK: Properties

    /// The departure date of the connection
    public let departureDate: Date
    /// The line name of the connection
    public let line: String
    /// The background color used to represent the connection
    public let backgroundColorCode: String
    /// The foreground color to  use when displaying the line with
    public let foregroundColorCode: String
    /// The departure delay
    public let departureDelay: TimeInterval
    /// The platform where the connection departs, if present.
    public let platform: String?
    /// Information about the terminus of the connection
    public let terminal: TimetableStopModel
    /// If the connection has a change in the original planned platform
    public var hasPlatformChange: Bool {
        platform?.contains("!") ?? false
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Parse the departure date
        departureDate = try container.decode(Date.self, forKey: .time)
        // Concatenate the line name from 3 components.
        let linePrefixRaw = try container.decodeIfPresent(String.self, forKey: .linePrefix)
        let lineSuffixRaw = try container.decodeIfPresent(String.self, forKey: .lineSuffix)
        switch (linePrefixRaw, lineSuffixRaw) {
            case let (.some(linePrefix), .some(lineSuffix)):
                if lineSuffix.count > 4 {
                    line = linePrefix
                } else {
                    line = linePrefix + "\u{00a0}" + lineSuffix
                }
            case let (.some(linePrefix), .none):
                line = linePrefix
            case let (.none, .some(lineSuffix)):
                line = lineSuffix
            case (.none, .none):
                line = try container.decodeIfPresent(String.self, forKey: .line) ?? "--"
        }

        // Parse the terminal
        terminal = try container.decode(TimetableStopModel.self, forKey: .terminal)
        // Parse the departure delay if present
        if let departureDelayString = try container.decodeIfPresent(String.self, forKey: .departureDelay) {
            if departureDelayString.starts(with: "+") {
                departureDelay = TimeInterval(departureDelayString.dropFirst()) ?? 0
            } else {
                departureDelay = 0
            }
        } else {
            departureDelay = 0
        }
        // Parse the platform if present
        platform = try container.decodeIfPresent(String.self, forKey: .track)

        // Colors
        let colorsRaw = try container.decodeIfPresent(String.self, forKey: .color)
        let colors = Self.decodeConnectionColors(colorsRaw)
        foregroundColorCode = colors.foreground
        backgroundColorCode = colors.background
    }

    private static func decodeConnectionColors(_ string: String?) -> (foreground: String, background: String) {
        let defaultValue = (foreground: "#fff", background: "#000")
        guard let string = string,
              let regex = try? NSRegularExpression(pattern: "^([a-z0-9]*)~([a-z0-9]*)~$", options: .caseInsensitive) else {
            return defaultValue
        }
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return defaultValue
        }

        guard match.numberOfRanges == 3 else {
            return defaultValue
        }

        let foreground: String
        let foregroundMatchRange = match.range(at: 1)
        if [3,6].contains(foregroundMatchRange.length), let foregroundRange = Range(foregroundMatchRange, in: string) {
            foreground = "#" + String(string[foregroundRange])
        } else {
            foreground = defaultValue.foreground
        }

        let background: String
        let backgroundMatchRange = match.range(at: 2)
        if [3,6].contains(backgroundMatchRange.length), let backgroundRange = Range(backgroundMatchRange, in: string) {
            background = "#" + String(string[backgroundRange])
        } else {
            background = defaultValue.background
        }

        return (background, foreground)

    }
}

// MARK: Coding Keys

extension TimetableConnectionModel {
    private enum CodingKeys: String, CodingKey {
        case time, color, terminal, track, line
        case linePrefix = "*G"
        case lineSuffix = "*L"
        case departureDelay = "dep_delay"
    }
}
