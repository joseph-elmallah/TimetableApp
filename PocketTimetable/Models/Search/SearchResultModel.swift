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

/// A model representing a  result of a search request
public struct SearchResultModel: Decodable, Hashable {

    // MARK: Properties

    /// The label of the search result
    public let label: String
    /// The icon representing the search result
    public let icon: SearchResultIcon
    /// The ID of the search result
    public let id: String?
    /// The distance to the station
    public let distance: Measurement<UnitLength>?

    // MARK: Initializers

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        let iconRaw = try container.decode(String.self, forKey: .iconclass)
        icon = SearchResultIcon(rawValue: iconRaw) ?? .generic
        id = try container.decodeIfPresent(String.self, forKey: .id)
        if let distanceInMeters = try container.decodeIfPresent(Double.self, forKey: .distance) {
            distance = Measurement(value: distanceInMeters, unit: UnitLength.meters)
        } else {
            distance = nil
        }
    }
}

// MARK: Coding Keys

extension SearchResultModel {
    private enum CodingKeys: String, CodingKey {
        case label, id, iconclass, distance = "dist"
    }
}
