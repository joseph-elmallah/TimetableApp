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

/// A view controller showing the timetable results of a timetable query.
final class TimetableViewController: UITableViewController {

    // MARK: Data Source
    /// The data source of the table view
    private lazy var dataSource = TimetableTableViewDiffableDataSource(tableView: tableView)

    // MARK: Subviews
    /// The message view serving as UI to the user for errors, empty state and loading state
    private lazy var messageView = MessageView()


    // MARK: Interface State Machine
    private enum InterfaceStateMachine {
        case empty, loading, loaded, failed(error: PTError)
    }

    private static let SFSymbolImageConfig = UIImage.SymbolConfiguration(pointSize: 35)
    private var interfaceSM: InterfaceStateMachine = .empty {
        didSet {
            switch interfaceSM {
                case .empty:
                    refreshControl?.endRefreshing()
                    messageView.isHidden = false
                    messageView.image = UIImage(systemName: "circle.dashed", withConfiguration: Self.SFSymbolImageConfig)
                    messageView.showsActivityIndicator = false
                    messageView.tintColor = .systemGray
                    messageView.title = "No Connections Found!"
                    messageView.subtitle = "There were no connections at that station. Please try again later."
                    messageView.action = MessageView.Action(title: "Retry", action: { [weak self] in
                        self?.reload()
                    })
                case .loading:
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
                        self?.timetableResponseModel = nil
                    })
                case .failed(error: let error):
                    refreshControl?.endRefreshing()
                    messageView.isHidden = false
                    messageView.image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: Self.SFSymbolImageConfig)
                    messageView.tintColor = .systemRed
                    messageView.showsActivityIndicator = false
                    messageView.title = "An Error occurred!"
                    messageView.subtitle = error.localizedDescription
                    messageView.action = MessageView.Action(title: "Retry", action: { [weak self] in
                        self?.reload()
                    })
                case .loaded:
                    refreshControl?.endRefreshing()
                    if dataSource.snapshot().numberOfItems == 0 {
                        messageView.isHidden = false
                        messageView.image = UIImage(systemName: "circle.dashed", withConfiguration: Self.SFSymbolImageConfig)
                        messageView.tintColor = .systemGray
                        messageView.showsActivityIndicator = false
                        messageView.title = "No Connections"
                        messageView.subtitle = "There are no connection passing by that station."
                        messageView.action = nil
                    } else {
                        messageView.isHidden = true
                    }
            }
        }
    }

    // MARK: Initializers

    /// Initialize the timetable view controller with a query
    /// - Parameter query: The query to use
    init(query: TimetableQuery? = nil) {
        super.init(style: .plain)
        self.query = query
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Deinitializer
    deinit {
        dataTaskStateObservation = nil
        dataTask?.cancel()
        updateTimer?.invalidate()
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        // Configure the table view
        tableView.dataSource = dataSource

        let refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Reload")
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        self.refreshControl = refreshControl

        tableView.tableFooterView = UIView()
        tableView.backgroundView = messageView
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44

        // Configure the message view
        messageView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let query = query, timetableResponseModel == nil, dataTask == nil {
            // Create a task when the view will be shown if we have all the necessary parameters
            // and the data has not yet bin loaded
            createDataTask(for: query)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dataTask?.resume()
        // Start and stop the auto reload when the app enters or leaves the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(cancelNextReload), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(scheduleNextUpdateOrReload), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataTask = nil
        cancelNextReload()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Query Manipulation

    /// The timetable model controller
    private let timetableModelController = TimetableModelController()

    /// The query representing the desired timetable to show
    var query: TimetableQuery? {
        didSet {
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
    private func createDataTask(for query: TimetableQuery) {
        let dataTask = timetableModelController.timetable(for: query) { [weak self] (result) in
            OperationQueue.main.addOperation { [weak self] in
                switch result {
                    case .success(let response):
                        let cleanConnections = TimetableViewControllerDataFormatter.removeDuplicates(from: response.connections)
                        let cleanResponse = TimetableResponseModel(stop: response.stop, connections: cleanConnections)
                        self?.timetableResponseModel = cleanResponse
                        self?.interfaceSM = .loaded
                        self?.nextRefreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
                        self?.scheduleNextUpdateOrReload()
                    case .failure(let error):
                        self?.timetableResponseModel = nil
                        self?.interfaceSM = .failed(error: error)
                        self?.cancelNextReload()
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
    private(set) var timetableResponseModel: TimetableResponseModel? {
        didSet {
            updateTitle()
            connectionsGroupedByDay = TimetableViewControllerDataFormatter.groupConnectionsByDay(response: timetableResponseModel)
        }
    }
    /// The parsed and grouped connections by date
    private var connectionsGroupedByDay: TimetableConnectionsGroupedByDay = [] {
        didSet {
            dataSource.apply(connectionsGroupedByDay: connectionsGroupedByDay, refresh: tableView)
        }
    }

    // MARK: Title
    private func updateTitle() {
        title = timetableResponseModel?.stop.name ?? query?.stationName ?? "No Station"
    }

    // MARK: Reload

    /// Reloads the data
    @objc private func reload() {
        guard let query = query else {
            dataTask = nil
            timetableResponseModel = nil
            return
        }
        updateTitle()
        createDataTask(for: query)
        if viewIfLoaded?.window != nil {
            dataTask?.resume()
        }
    }

    /// If `true` the UI will refresh and animate it's content every minute, keeping the visible data up to date
    var autoRefreshConnection = true {
        didSet {
            guard autoRefreshConnection != oldValue else { return }
            autoRefreshConnection ? scheduleNextUpdateOrReload() : cancelNextReload()
        }
    }

    /// Keep track of when the next refresh date is due
    private var nextRefreshDate: Date?
    /// The update timer signaling when to refresh
    private var updateTimer: Timer?

    /// If the refresh date is due, a reload will be performed. Otherwise a timer is set to fire on the refresh date value.
    @objc private func scheduleNextUpdateOrReload() {
        guard let nextRefreshDate = nextRefreshDate,
              nextRefreshDate > Date() else {
            if dataTask?.state != .running {
                reload()
            }
            return
        }

        updateTimer?.invalidate()
        guard autoRefreshConnection else {
            return
        }

        updateTimer = Timer.scheduledTimer(withTimeInterval: nextRefreshDate.timeIntervalSinceNow, repeats: false, block: { [weak self] (_) in
            self?.reload()
        })
    }

    /// Cancels any scheduled refresh
    @objc private func cancelNextReload() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
