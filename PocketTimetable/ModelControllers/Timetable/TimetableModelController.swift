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

/// A model controller that can generate data tasks accessing the timetable API.
public final class TimetableModelController: BaseModelController {

    /// A JSON Decoder for requests body parsing
    private static let jsonDecoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()

    /// Gets the timetable for the given query.
    ///
    /// This task is not started and it's the caller's responsibility to `resume()` and to maintain a reference to it.
    ///
    /// - Parameters:
    ///   - query: The query to execute.
    ///   - completion: A completion handler called upon completion or failure.
    /// - Returns: A `URLSessionDataTask`
    public func timetable(for query: TimetableQuery, completion: @escaping (_ result: Result<TimetableResponseModel, PTError>) -> Void) -> URLSessionDataTask? {
        do {
            let request = try TimetableAPI.stationboard(query: query, environment: environment)
            let dataTask = NetworkingHelper.getDataTask(decoder: Self.jsonDecoder, session: session, request: request, completion: completion)
            return dataTask
        } catch let error as PTError {
            completion(.failure(error))
        } catch {
            completion(.failure(.networkingError(wrappedError: error, debugDescription: "Unknown error")))
        }
        return nil
    }
}
