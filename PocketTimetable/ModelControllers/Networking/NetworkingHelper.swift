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

/// A helper that groups similar networking code
enum NetworkingHelper {

    /// Helper function to create a data task that handles errors and parse the returned data
    ///
    /// The returned `URLSessionDataTask` is not started and not retained
    ///
    /// - Parameters:
    ///   - jsonDecoder: A JSON decoder to be used when the body needs to be parsed
    ///   - session: A session to generate the data task from
    ///   - request: A request to execute
    ///   - completion: A completion block called when the task succeeded or failed
    /// - Returns: A `URLSessionDataTask`
    static func getDataTask<T: Decodable>(
        decoder jsonDecoder: JSONDecoder = JSONDecoder(),
        session: URLSession,
        request: URLRequest,
        completion: @escaping (Result<T, PTError>) -> Void
    ) -> URLSessionDataTask {

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(.failure(.networkingError(wrappedError: error, debugDescription: "Data task failed")))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkingError(wrappedError: nil, debugDescription: "Response is not HTTP")))
                return
            }
            guard httpResponse.statusCode == 200 else {
                let dataAsString: String?
                if let data = data {
                    dataAsString = String(data: data, encoding: .utf8)
                } else {
                    dataAsString = nil
                }
                completion(.failure(.responseError(status: httpResponse.statusCode, bodyAsString: dataAsString)))
                return
            }

            guard let data = data else {
                completion(.failure(.dataError(wrappedError: nil, debugDescription: "No data")))
                return
            }
            do {
                let decodedModel = try jsonDecoder.decode(T.self, from: data)
                completion(.success(decodedModel))
            } catch {
                completion(.failure(.dataError(wrappedError: error, debugDescription: "Decoding failed")))
            }
        }
        return dataTask
    }

    /// Helper function to concatenate different parameters into a valid URL.
    /// - Parameters:
    ///   - path: The path of the resource
    ///   - queryItems: The query items to use
    ///   - environment: The environment to use
    /// - Throws: `PTError` if the URL was not valid and could not be created
    /// - Returns: A valid `URL` built from the passed parameters
    static func createEndpointURL(withPath path: String, queryItems: [URLQueryItem], environment: Environment) throws -> URL {
        let url = environment.baseURL.appendingPathComponent(path)
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PTError.networkingError(wrappedError: nil, debugDescription: "Cannot create components from URL \(environment.baseURL)")
        }
        urlComponents.queryItems = queryItems
        guard let endpointURL = urlComponents.url else {
            throw PTError.networkingError(wrappedError: nil, debugDescription: "Cannot create endpoint URL")
        }
        return endpointURL
    }
}
