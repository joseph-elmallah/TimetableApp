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
import CoreLocation

/// A view controller showing nearby stations or text search result stations.
final class SearchViewController: UITableViewController {

    // MARK: Data Source
    /// The data source of the table view
    private lazy var dataSource = SearchViewDiffableDataSource(tableView: tableView)

    // MARK: Subviews
    /// The message view serving as UI to the user for errors, empty state and loading state
    private lazy var messageView = MessageView()

    // MARK: State Machines
    private enum InterfaceStateMachine {
        case empty, loading, loaded, failed(error: PTError)
    }

    private enum LocationStateMachine {
        case notAvailable
        case notAsked
        case asking
        case limitedAccuracy
        case notAllowed
        case allowedButNotStarted
        case started
        case error(error: PTError)
    }

    private var interfaceSM: InterfaceStateMachine = .empty { didSet { updateMessageView() } }
    private var locationSM: LocationStateMachine = .notAvailable { didSet { updateMessageView() } }

    private static let SFSymbolImageConfig = UIImage.SymbolConfiguration(pointSize: 35)
    private func updateMessageView() {
        switch (interfaceSM, locationSM) {
            case (.empty, .notAvailable):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = false
                messageView.tintColor = .systemGray
                messageView.title = "Search for a station"
                messageView.subtitle = "Tap the search bar to start."
                messageView.action = nil
            case (.empty, .notAsked):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "location.fill", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = false
                messageView.tintColor = .systemGray
                messageView.title = "Allow location services"
                messageView.subtitle = "When location services are allowed, nearby stations will be automatically shown."
                messageView.action = MessageView.Action(title: "Activate Location", action: { [weak self] in
                    self?.locationManager.requestWhenInUseAuthorization()
                    self?.locationSM = .asking
                })
            case (.empty, .asking):
                messageView.isHidden = true
                messageView.action = nil
            case (.empty, .limitedAccuracy):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = false
                messageView.tintColor = .systemGray
                messageView.title = "Search for a station"
                messageView.subtitle = "Tap the search bar to start, or grant the app temporary accurate location."
                messageView.action = MessageView.Action(title: "Temporary Accurate Location", action: { [weak self] in
                    self?.locationSM = .asking
                    self?.locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "FetchNearbyStations", completion: { [weak self] error in
                        guard let self = self, let error = error else {
                            return
                        }
                        if case .asking = self.locationSM {
                            self.locationSM = .limitedAccuracy
                        }
                        let alertController = UIAlertController(title: "Full location accuracy failed", message: "Something went wrong when asking for full location accuracy. Try again or change it manually from the settings. \(error)", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                        self.present(alertController, animated: true, completion: nil)
                    })
                })
            case (.empty, .notAllowed):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = false
                messageView.tintColor = .systemGray
                messageView.title = "Search for a station"
                messageView.subtitle = "Tap the search bar to start, or update your settings to grant accurate  location permissions to fetch nearby stations."
                messageView.action = MessageView.Action(title: "Open Settings", action: { [weak self] in
                    self?.openSettings()
                })
            case (.empty, .allowedButNotStarted):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "magnifyingglass", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = false
                messageView.tintColor = .systemGray
                messageView.title = "Search for a station"
                messageView.subtitle = "Tap the search bar to start. Or use your location to fetch nearby stations"
                messageView.action = MessageView.Action(title: "Fetch nearby stations", action: { [weak self] in
                    self?.locationSM = .started
                    self?.locationManager.startUpdatingLocation()
                })
            case (.empty, .started):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "location.viewfinder", withConfiguration: Self.SFSymbolImageConfig)
                messageView.showsActivityIndicator = true
                messageView.tintColor = .systemBlue
                messageView.title = "Determining your location..."
                messageView.subtitle = nil
                messageView.action = MessageView.Action(title: "Cancel", action: { [weak self] in
                    self?.locationManager.stopUpdatingLocation()
                    self?.locationSM = .allowedButNotStarted
                })
            case (.empty, .error(error: let error)):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "location.slash", withConfiguration: Self.SFSymbolImageConfig)
                messageView.tintColor = .systemRed
                messageView.showsActivityIndicator = false
                messageView.title = "Could not load your location!"
                messageView.subtitle = error.localizedDescription
                messageView.action = MessageView.Action(title: "Retry", action: { [weak self] in
                    self?.locationSM = .started
                    self?.locationManager.startUpdatingLocation()
                })
            case (.loading, _):
                guard dataSource.snapshot().numberOfItems == 0 else {
                    messageView.isHidden = true
                    return
                }
                messageView.isHidden = false
                messageView.image = nil
                messageView.showsActivityIndicator = true
                messageView.title = "Loading..."
                messageView.subtitle = nil
                messageView.action = MessageView.Action(title: "Cancel", action: { [weak self] in
                    self?.dataTask = nil
                    self?.searchResults = nil
                    self?.interfaceSM = .empty
                })
            case (.failed(error: let error), _):
                messageView.isHidden = false
                messageView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: Self.SFSymbolImageConfig)
                messageView.tintColor = .systemRed
                messageView.showsActivityIndicator = false
                messageView.title = "An Error occurred!"
                messageView.subtitle = error.localizedDescription
                messageView.action = MessageView.Action(title: "Retry", action: { [weak self] in
                    self?.reload()
                })
            case (.loaded, _):
                if dataSource.snapshot().numberOfItems == 0 {
                    messageView.isHidden = false
                    messageView.image = UIImage(systemName: "circle.dashed", withConfiguration: Self.SFSymbolImageConfig)
                    messageView.tintColor = .systemGray
                    messageView.showsActivityIndicator = false
                    messageView.title = "No Results"
                    messageView.subtitle = "Your given search phrase didn't yeald any results. Verify the spelling or try altering the order."
                    messageView.action = nil
                } else {
                    messageView.isHidden = true
                }
        }
    }

    deinit {
        dataTaskStateObservation = nil
        dataTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Nearby Stations"

        navigationItem.largeTitleDisplayMode = .automatic

        // Configure the table view
        tableView.dataSource = dataSource

        tableView.tableFooterView = UIView()
        tableView.backgroundView = messageView
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        // Configure the search bar
        searchController.searchResultsUpdater = self
        searchController.searchBar.sizeToFit()
        searchController.obscuresBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true

        guard CLLocationManager.locationServicesEnabled() else {
            locationSM = .notAvailable
            return
        }
        // Configure location state machine
        switch (locationManager.authorizationStatus, locationManager.accuracyAuthorization) {
            case (.authorizedAlways, .fullAccuracy),
                 (.authorizedWhenInUse, .fullAccuracy):
                locationSM = .allowedButNotStarted
            case (.authorizedWhenInUse, .reducedAccuracy),
                 (.authorizedAlways, .reducedAccuracy):
                locationSM = .limitedAccuracy
            case (.denied, _),
                 (.restricted, _):
                locationSM = .notAllowed
            case (.notDetermined, _):
                locationSM = .notAsked
            default:
                locationSM = .notAvailable
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let query = query, searchResults == nil, dataTask == nil {
            // Create a task when the view will be shown if we have all the necessary parameters
            // and the data has not yet bin loaded
            createDataTask(for: query)
        }
        if case .allowedButNotStarted = locationSM {
            // Start location update if permitted
            locationSM = .started
            locationManager.startUpdatingLocation()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dataTask?.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataTask = nil
    }

    // MARK: Query Manipulation
    /// The search model controller
    private let searchModelController = SearchModelController()
    /// The query representing the desired search to show
    var query: SearchQuery? {
        get { userDefinedQuery ?? locationQuery }
        set { userDefinedQuery = newValue }
    }
    /// The query generated from the text input
    private var userDefinedQuery: SearchQuery? {
        didSet {
            reload()
        }
    }
    /// The query generated from the location
    private var locationQuery: SearchQuery? {
        didSet {
            guard userDefinedQuery == nil else { return }
            reload()
        }
    }


    // MARK: Data task manipulation

    /// Observs the changes in the state of the data task
    private var dataTaskStateObservation: NSKeyValueObservation?
    /// The current running data task
    private var dataTask: URLSessionDataTask? {
        willSet { dataTask?.cancel() }
    }
    /// Factory method to build a data task from a query
    /// - Parameter query: The query to execute
    private func createDataTask(for query: SearchQuery) {
        let dataTask = searchModelController.autocomplete(query: query) { [weak self] (result) in
            OperationQueue.main.addOperation { [weak self] in
                switch result {
                    case .success(let response):
                        self?.searchResults = response.filter({ $0.id != nil })
                        self?.interfaceSM = .loaded
                    case .failure(let error):
                        self?.searchResults = nil
                        self?.interfaceSM = .failed(error: error)
                }
            }
        }

        dataTaskStateObservation = dataTask?.observe(\.state, changeHandler: { [weak self] (dataTask, _) in
            if case .running = dataTask.state {
                OperationQueue.main.addOperation { [weak self] in
                    self?.interfaceSM = .loading
                }
            }
        })

        self.dataTask = dataTask
    }

    // MARK: Response Model

    /// The response from the timetable API
    private(set) var searchResults: [SearchResultModel]? {
        didSet {
            dataSource.apply(searchResults: searchResults ?? [])
        }
    }

    // MARK: Reload

    /// Reloads the data
    private func reload() {
        guard let query = query else {
            dataTask = nil
            searchResults = nil
            interfaceSM = .empty
            return
        }
        createDataTask(for: query)
        if viewIfLoaded?.window != nil {
            dataTask?.resume()
        }
    }

    // MARK: Helpers

    /// Opens the app settings page in the settings app
    private func openSettings() {
        func showAlert(_ vc: UIViewController?) {
            let alertController = UIAlertController(title: "Cannot open settings", message: "Opening settings is not possible at the moment. Please try to navigate to settings manually.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            vc?.present(alertController, animated: true, completion: nil)
        }
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else {
            showAlert(self)
            return
        }
        UIApplication.shared.open(settingsURL, options: [:]) { [weak self] (success) in
            if success == false {
                showAlert(self)
            }
        }
    }


    // MARK: Location

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.activityType = .other
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 30
        userLocation = canUseLocation(manager.location)
        return manager
    }()

    private var userLocation: CLLocation? {
        didSet {
            guard let coordinates = userLocation?.coordinate else {
                return
            }
            locationQuery = LocationSearchQuery(coordinate: coordinates, accuracy: userLocation?.horizontalAccuracy)
        }
    }

    // MARK: Search Bar
    private lazy var searchController = UISearchController(searchResultsController: nil)

}

// MARK: Protocol Conforming
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.isActive else {
            return
        }

        guard let filterString = searchController.searchBar.text, filterString.isEmpty == false else {
            query = nil
            return
        }
        query = TextSearchQuery(text: filterString)
    }
}

extension SearchViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let result = searchResults?[indexPath.row] else {
            return
        }
        let query = TimetableQuery(stationName: result.label, showPlatforms: true)
        let timetableViewController = TimetableViewController(query: query)
        navigationController?.pushViewController(timetableViewController, animated: true)
    }
}

// MARK: CLLocationManagerDelegate

extension SearchViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard CLLocationManager.locationServicesEnabled() else {
            locationManager.stopUpdatingLocation()
            locationSM = .notAvailable
            return
        }
        switch (manager.authorizationStatus, manager.accuracyAuthorization) {
            case (.authorizedAlways, .fullAccuracy),
                 (.authorizedWhenInUse, .fullAccuracy):
                switch locationSM {
                    case .started:
                        break
                    case .asking:
                        locationSM = .started
                        locationManager.startUpdatingLocation()
                    default:
                        locationSM = .allowedButNotStarted
                }
            case (.authorizedAlways, .reducedAccuracy),
                 (.authorizedWhenInUse, .reducedAccuracy):
                locationManager.stopUpdatingLocation()
                locationSM = .limitedAccuracy
            case (.denied, _),
                 (.restricted, _):
                locationManager.stopUpdatingLocation()
                locationSM = .notAllowed
            case (.notDetermined, _):
                locationSM = .notAsked
            default:
                locationManager.stopUpdatingLocation()
                locationSM = .notAvailable
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = canUseLocation(locations.first)
    }

    fileprivate func canUseLocation(_ location: CLLocation?) -> CLLocation? {
        guard let location = location else {
            return nil
        }
        guard location.horizontalAccuracy < kCLLocationAccuracyHundredMeters else {
            return nil
        }
        guard location.timestamp.timeIntervalSinceNow > -5 * 60 else {
            return nil
        }
        return location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        if CLLocationManager.locationServicesEnabled() {
            locationSM = .error(error: PTError.locationError(wrappedError: error))
        } else {
            locationSM = .notAvailable
        }
    }
}
