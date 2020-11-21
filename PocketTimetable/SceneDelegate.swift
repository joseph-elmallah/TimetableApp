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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// The associated window of the scene
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Root View Controllers
        let searchViewController = SearchViewController()
        let departureBoardViewController = TimetableViewController()

        // Navigation View Controller
        let primaryNavigationController = UINavigationController(rootViewController:searchViewController)
        primaryNavigationController.navigationBar.prefersLargeTitles = true
        let secondaryNavigationController = UINavigationController(rootViewController:departureBoardViewController)
        secondaryNavigationController.navigationBar.prefersLargeTitles = true

        // Split View Controller
        let splitViewController =  UISplitViewController()
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        splitViewController.viewControllers = [
            primaryNavigationController,
            secondaryNavigationController
        ]

        // Main window
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = splitViewController
        self.window = window
        window.makeKeyAndVisible()
    }

}

extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

