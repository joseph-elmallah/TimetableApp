//
//  TimetableConnectionModel.swift
//  PocketTimetable
//
//  Created by Joseph El Mallah on 16.11.20.
//

import Foundation

public struct TimetableConnectionModel: Decodable, Hashable {

    public let departureDate: Date
    public let line: String
    public let backgroundColorCode: String
    public let foregroundColorCode: String
    public let departureDelay: String?
    public let track: String?
    public let terminal: TerminalModel

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        departureDate = try container.decode(Date.self, forKey: .time)
        let linePrefixRaw = try container.decodeIfPresent(String.self, forKey: .linePrefix)
        let lineSuffixRaw = try container.decodeIfPresent(String.self, forKey: .lineSuffix)
        switch (linePrefixRaw, lineSuffixRaw) {
            case let (.some(linePrefix), .some(lineSuffix)):
                line = linePrefix + "\u{00a0}" + lineSuffix
            case let (.some(linePrefix), .none):
                line = linePrefix
            case let (.none, .some(lineSuffix)):
                line = lineSuffix
            case (.none, .none):
                line = try container.decodeIfPresent(String.self, forKey: .line) ?? "--"
        }

        terminal = try container.decode(TerminalModel.self, forKey: .terminal)
        departureDelay = try container.decodeIfPresent(String.self, forKey: .departureDelay)
        track = try container.decodeIfPresent(String.self, forKey: .track)

        // Decode color
        let colorsRaw = try container.decode(String.self, forKey: .color)
        guard let colors = colorsRaw.decodeConnectionColors() else {
            throw DecodingError.dataCorruptedError(forKey: CodingKeys.color, in: container, debugDescription: "Color doesn't contain two parts! \(colorsRaw)")
        }
        foregroundColorCode = "#\(colors.foreground)"
        backgroundColorCode = "#\(colors.background)"
    }

    private enum CodingKeys: String, CodingKey {
        case time, color, terminal, track, line
        case linePrefix = "*G"
        case lineSuffix = "*L"
        case departureDelay = "dep_delay"
    }
}

public struct TerminalModel: Decodable, Hashable {
    public let id: String
    public let name: String
}

private extension String {
    func decodeConnectionColors() -> (foreground: String, background: String)? {
        let colorComponents = components(separatedBy: "~")
        guard colorComponents.count > 1 else {
            return nil
        }
        return (colorComponents[1], colorComponents[0])
    }
}
