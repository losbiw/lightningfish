// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

///Email dates may be absolute or relative to current date based on app settings
///Smart Dates are relative to the current date, localized
///Today, Yesterday, Month Day, and Month Day Year
@MainActor
public struct SmartDateFormatter {
    func dateFormatter(date: Date, isSmartDate: Bool) -> String {
        if isSmartDate {
            return smartDate(date: date)
        }
        return fullDateFormatter(date: date)
    }

    private func fullDateFormatter(date: Date) -> String {
        return date.formatted(date: .numeric, time: .omitted)
    }

    /// - Returns:
    /// If date is before the current calendar year, return date in Month, day, year format, localized
    /// If date is today or yesterday, return those strings, localized
    /// If date is within the current calendar year but before yesterday, return date in Month, day format, localized
    private func smartDate(date: Date) -> String {
        if Calendar.autoupdatingCurrent.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if Calendar.autoupdatingCurrent.isDateInYesterday(date) {
            let relativeDateFormatter = RelativeDateTimeFormatter()
            return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
        } else if !Calendar.autoupdatingCurrent.isDate(date, equalTo: Date(), toGranularity: .year) {
            return date.formatted(.dateTime.month(.abbreviated).day().year())
        } else {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
    }
}
