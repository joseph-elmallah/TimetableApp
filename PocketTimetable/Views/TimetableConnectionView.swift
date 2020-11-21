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

/// A view to display a timetable connection
///
/// The view featurs: line with coloration, destination, platform, remaining minutes to departure and delays
final class TimetableConnectionView: UIStackView {

    // MARK: Properties

    /// A formatter for the countdown to departure
    private static let dateComponentFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        return formatter
    }()

    // MARK: Subviews

    private let lineLabel = PaddedLabel()
    private let destinationLabel = UILabel()
    private let platformLabel = UILabel()
    private let countdownLabel = UILabel()

    // MARK: Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Setup the view hierarchy
        let textsStackView = UIStackView(arrangedSubviews: [
            destinationLabel,
            platformLabel
        ])
        addArrangedSubview(lineLabel)
        addArrangedSubview(textsStackView)
        addArrangedSubview(countdownLabel)

        // Styling of the view and subviews

        axis = .horizontal
        alignment = .center
        distribution = .fill
        spacing = 10

        textsStackView.axis = .vertical
        textsStackView.alignment = .fill
        textsStackView.distribution = .fill

        lineLabel.font = .preferredFont(forTextStyle: .title3)
        lineLabel.numberOfLines = 1
        lineLabel.textAlignment = .center
        lineLabel.layer.cornerRadius = 5
        lineLabel.clipsToBounds = true
        lineLabel.edgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
        lineLabel.isHidden = true

        destinationLabel.font = .preferredFont(forTextStyle: .headline)
        destinationLabel.textColor = .label
        destinationLabel.numberOfLines = 0
        destinationLabel.isHidden = true
        destinationLabel.adjustsFontForContentSizeCategory = true

        platformLabel.font = .preferredFont(forTextStyle: .subheadline)
        platformLabel.textColor = .secondaryLabel
        platformLabel.numberOfLines = 1
        platformLabel.isHidden = true
        platformLabel.adjustsFontForContentSizeCategory = true

        countdownLabel.font = .preferredFont(forTextStyle: .headline)
        countdownLabel.textColor = .label
        countdownLabel.numberOfLines = 1
        countdownLabel.textAlignment = .right
        countdownLabel.isHidden = true
        countdownLabel.adjustsFontForContentSizeCategory = true

        // Layouting
        destinationLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)
        platformLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)
        textsStackView.setContentHuggingPriority(UILayoutPriority(rawValue: 200), for: .horizontal)

        destinationLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 700), for: .horizontal)
        platformLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 700), for: .horizontal)
        textsStackView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 700), for: .horizontal)

        NSLayoutConstraint.activate([
            lineLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Accessors

    /// Set the platform
    /// - Parameters:
    ///   - newPlatform: The new value of the platform
    ///   - hasChanges: If it should highlight the platform change
    func setPlatform(_ newPlatform: String?, hasChanges: Bool) {
        platformLabel.text = newPlatform
        platformLabel.isHidden = newPlatform == nil
        platformLabel.textColor = hasChanges ? .systemOrange : .secondaryLabel
    }

    /// The platform on which the connection will departs
    var platform: String? { platformLabel.text }

    /// Set the coundown and delay
    /// - Parameters:
    ///   - departureDate: The date to departure to use
    ///   - delay: The delay added to the departure time
    func setCountdown(departureDate: Date, delay: TimeInterval) {

        let timeToDeparture = departureDate.timeIntervalSinceNow
        let timeToDepartureWithDelay = timeToDeparture + delay

        if timeToDepartureWithDelay < -60 {
            // Connection is in the past
            countdownLabel.text = nil
            countdownLabel.isHidden = true
            return
        }

        if timeToDepartureWithDelay < 60 {
            countdownLabel.text = "now"
            countdownLabel.textColor = delay > 0 ? .systemOrange : .systemGreen

        } else if delay > 0, let text = Self.dateComponentFormatter.string(from: timeToDepartureWithDelay) {

            let imageAttachment = NSTextAttachment()
            imageAttachment.image = UIImage(
                systemName: "clock.arrow.circlepath",
                withConfiguration: UIImage.SymbolConfiguration(font: countdownLabel.font))?
                .withRenderingMode(.alwaysTemplate)

            let fullString = NSMutableAttributedString(attachment: imageAttachment)
            fullString.append(NSAttributedString(string: "\u{00a0}\(text)"))

            countdownLabel.attributedText = fullString
            countdownLabel.textColor = .systemOrange

        } else {
            countdownLabel.text = Self.dateComponentFormatter.string(from: timeToDepartureWithDelay)
            countdownLabel.textColor = .label
        }

        countdownLabel.isHidden = countdownLabel.text == nil

    }

    /// The coundown value
    var countdown: String? { countdownLabel.text }

    /// The line model
    var line: LineModel? {
        didSet {
            lineLabel.isHidden = line == nil
            if let line = line {
                lineLabel.backgroundColor = line.backgroundColor
                if line.backgroundColor == UIColor.white {
                    lineLabel.layer.borderWidth = 1
                    lineLabel.layer.borderColor = UIColor.systemGray.cgColor
                } else {
                    lineLabel.layer.borderWidth = 0
                }
                lineLabel.textColor = line.foregroundColor
                lineLabel.text = line.name
            }
        }
    }

    /// The destination of the connection
    var destination: String? {
        get { destinationLabel.text }
        set {
            destinationLabel.text = newValue
            destinationLabel.isHidden = newValue == nil
        }
    }
}

// MARK: Helper Class and Extensions

extension TimetableConnectionView {
    /// A model describing a line
    struct LineModel {
        /// The background color of the line view
        var backgroundColor: UIColor?
        /// The foreground color of the line used for the font color
        var foregroundColor: UIColor?
        /// The display name of the line
        var name: String?

        init(name: String? = nil, foregroundColor: UIColor? = nil, backgroundColor: UIColor? = nil) {
            self.name = name
            self.foregroundColor = foregroundColor
            self.backgroundColor = backgroundColor
        }

        init(name: String? = nil, foregroundColorHex: String, backgroundColorHex: String) {
            self.name = name
            foregroundColor = UIColor(hex: foregroundColorHex)
            backgroundColor = UIColor(hex: backgroundColorHex)
        }
    }
}

/// A padded label
private final class PaddedLabel: UILabel {

    /// The edges insets to apply around the text
    var edgeInsets: UIEdgeInsets = .zero {
        didSet { setNeedsDisplay() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }

    override var intrinsicContentSize: CGSize {
        let originalSize = super.intrinsicContentSize
        return CGSize(width: originalSize.width + edgeInsets.left + edgeInsets.right,
                      height: originalSize.height + edgeInsets.top + edgeInsets.bottom)
    }
}

private extension UIColor {
    /// Converts a HEX string into a color
    /// - Parameter hex: The hex string to parse the color from
    convenience init?(hex: String) {
        guard hex.hasPrefix("#") else {
            return nil
        }

        let hexString: String = String(hex[String.Index(utf16Offset: 1, in: hex)...])
        var hexValue:  UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexValue) else {
            return nil
        }

        if hexString.count == 3 {
            let divisor = CGFloat(15)
            let red     = CGFloat((hexValue & 0xF00) >> 8) / divisor
            let green   = CGFloat((hexValue & 0x0F0) >> 4) / divisor
            let blue    = CGFloat( hexValue & 0x00F      ) / divisor
            self.init(red: red, green: green, blue: blue, alpha: 1.0)
        } else if hexString.count == 6 {
            let divisor = CGFloat(255)
            let red     = CGFloat((hexValue & 0xFF0000) >> 16) / divisor
            let green   = CGFloat((hexValue & 0x00FF00) >>  8) / divisor
            let blue    = CGFloat( hexValue & 0x0000FF       ) / divisor
            self.init(red: red, green: green, blue: blue, alpha: 1.0)
        } else {
            return nil
        }
    }

    static func == (l: UIColor, r: UIColor) -> Bool {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        l.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        r.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return r1 == r2 && g1 == g2 && b1 == b2 && a1 == a2
    }
}

private func == (l: UIColor?, r: UIColor?) -> Bool {
    let l = l ?? .clear
    let r = r ?? .clear
    return l == r
}
