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

/// A view that can display a message
///
/// This view has the potential of displaying one or more of the following at the same time (ordered from top to bottom):
/// - An Image, an activity indicator, a title, a subtitle and a button
/// Main use is to display messages for the user like empty data, loading status or errors
final class MessageView: UIView {

    // MARK: Properties

    /// An action. If not `nil` a button will be shown using the data provided in the model
    var action: Action? {
        didSet {
            actionButton.setTitle(action?.title, for: .normal)
            actionButton.isHidden = action == nil
        }
    }

    // MARK: Subviews
    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Hierarchy
        let stackView = UIStackView(arrangedSubviews: [
            imageView,
            activityIndicator,
            titleLabel,
            subtitleLabel,
            actionButton
        ])
        addSubview(stackView)

        // Layout
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let centerXConstraint = stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
        centerXConstraint.priority = UILayoutPriority(999)
        let centerYConstraint = stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        centerYConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            centerXConstraint,
            centerYConstraint,
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.leadingAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.topAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: readableContentGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: readableContentGuide.bottomAnchor),
        ])

        // Configuration
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10

        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textColor = .systemGray
        subtitleLabel.textAlignment = .center

        activityIndicator.hidesWhenStopped = true
        imageView.tintColor = tintColor

        // Actions
        actionButton.addTarget(self, action: #selector(actionTouchUpInside(_:)), for: .touchUpInside)
        actionButton.tintColor = .systemBlue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Accessors

    /// An image. Hidden if `nil`
    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            imageView.isHidden = newValue == nil
        }
    }

    /// A title. Hidden if `nil`
    var title: String? {
        get { titleLabel.text }
        set {
            titleLabel.text = newValue
            titleLabel.isHidden = newValue == nil
        }
    }

    /// A subtitle. Hidden if `nil`
    var subtitle: String? {
        get { subtitleLabel.text }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = newValue == nil
        }
    }

    /// If `true` an activity indicator will be shown
    var showsActivityIndicator: Bool {
        get { activityIndicator.isAnimating }
        set { newValue ? activityIndicator.startAnimating() : activityIndicator.stopAnimating() }
    }

    override var tintColor: UIColor! {
        didSet {
            imageView.tintColor = tintColor
        }
    }

    // MARK: Other

    @objc
    private func actionTouchUpInside(_ button: UIButton) {
        action?.action()
    }
}

// MARK: Helper Classes
extension MessageView {
    /// A model of an action
    struct Action {
        /// The display title of the action
        let title: String
        /// The execution of the action
        let action: () -> Void
    }
}
