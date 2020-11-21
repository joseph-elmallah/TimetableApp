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

/// The search API builder
enum SearchAPI {

    // MARK: Main functions

    /// Builds a request destined for the search API
    /// - Parameters:
    ///   - query: The query to execute
    ///   - environment: The environment to use
    /// - Throws: `PTError` in case of networking or parsing errors
    /// - Returns: A `URLRequest` configured with the query and environment
    static func autocomplete(query: SearchQuery, environment: Environment) throws -> URLRequest {
        let queryItems = query.queryItems + [
            URLQueryItem(name: "show_ids", value: "1"),
        ]
        let endpointURL = try NetworkingHelper.createEndpointURL(withPath: "completion.json", queryItems: queryItems, environment: environment)
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "GET"
        return request
    }
}

// MARK: Helper Protocol
/// Conforming types can be passes as query for the search API
public protocol SearchQuery {
    var queryItems: [URLQueryItem] { get }
}

extension TextSearchQuery: SearchQuery {
    public var queryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "term", value: text),
            URLQueryItem(name: "nofavorites", value: "1")
        ]
    }
}

extension LocationSearchQuery: SearchQuery {
    private static let accuracyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        formatter.numberStyle = .none
        return formatter
    }()

    public var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "latlon", value: "\(coordinate.latitude),\(coordinate.longitude)")
        ]
        if let accuracy = accuracy,
           let formattedAccuracy = Self.accuracyFormatter.string(from: NSNumber(floatLiteral: accuracy)) {
            items.append(URLQueryItem(name: "accuracy", value: formattedAccuracy))
        }
        return items
    }
}


