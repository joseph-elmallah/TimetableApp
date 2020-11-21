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
import SnapKit

final class SearchResultView: UIView {

    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .medium
        return formatter
    }()

    private let imageView = UIImageView()
    private let autocompletedLabel = UILabel()
    private let distanceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Hierarchy
        addSubview(imageView)
        let labelsStackView = UIStackView(arrangedSubviews: [
            autocompletedLabel,
            distanceLabel
        ])
        addSubview(labelsStackView)

        // Layouting
        imageView.snp.makeConstraints { (make) in
            make.leading.equalTo(layoutMarginsGuide)
            make.top.greaterThanOrEqualTo(layoutMarginsGuide)
            make.bottom.lessThanOrEqualTo(layoutMarginsGuide)
            make.centerY.equalToSuperview().priority(900)
        }

        labelsStackView.snp.makeConstraints { (make) in
            make.leading.equalTo(imageView.snp.trailing).offset(10)
            make.top.greaterThanOrEqualTo(layoutMarginsGuide)
            make.bottom.lessThanOrEqualTo(layoutMarginsGuide)
            make.centerY.equalToSuperview().priority(900)
            make.trailing.equalTo(layoutMarginsGuide)
        }

        // Styling
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label

        labelsStackView.axis = .vertical
        labelsStackView.distribution = .fill
        labelsStackView.alignment = .leading

        autocompletedLabel.font = .preferredFont(forTextStyle: .headline)
        autocompletedLabel.numberOfLines = 0
        autocompletedLabel.isHidden = true
        autocompletedLabel.adjustsFontForContentSizeCategory = true

        distanceLabel.font = .preferredFont(forTextStyle: .subheadline)
        distanceLabel.textColor = .secondaryLabel
        distanceLabel.numberOfLines = 1
        distanceLabel.isHidden = true
        distanceLabel.adjustsFontForContentSizeCategory = true

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Accessors

    static let SFSymbolImageConfig = UIImage.SymbolConfiguration(pointSize: 22)

    /// The transport type to update the icon
    var transportationType: SearchResultIcon? {
        didSet {
            guard let transportationType = transportationType else {
                imageView.image = nil
                imageView.isHidden = true
                return
            }

            let imageName: String
            switch transportationType {
                case .address:
                    imageName = "pin.fill"
                case .bus:
                    imageName = "bus.fill"
                case .tram:
                    imageName = "tram.fill"
                case .train:
                    imageName = "tram.tunnel.fill"
                case .generic:
                    imageName = "magnifyingglass.circle"
            }

            imageView.image = UIImage(systemName: imageName, withConfiguration: Self.SFSymbolImageConfig)
            imageView.isHidden = false
        }
    }

    /// The autocompletion result label to display
    var autocompletionResult: String? {
        get { autocompletedLabel.text }
        set {
            autocompletedLabel.text = newValue
            autocompletedLabel.isHidden = newValue == nil
        }
    }

    /// The distance separating the user from the search result item
    var distance: Measurement<UnitLength>? {
        didSet {
            guard let distance = distance else {
                distanceLabel.text = nil
                distanceLabel.isHidden = true
                return
            }
            if distance.value == 0 {
                distanceLabel.text = "Nearby"
            } else {
                distanceLabel.text = Self.distanceFormatter.string(from: distance) + " away"
            }
            distanceLabel.isHidden = false
        }
    }

}
