// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Testing

@MainActor @Suite("Smart Date Formatter tests") struct SmartDateFormatterTests {
    var oldDate: Date
    var thisYearDate: Date
    var yesterdayDate: Date
    var todayDate: Date

    init() async throws {
        let calendar = Calendar.autoupdatingCurrent
        let year = calendar.component(.year, from: Date())
        var dateCompon = DateComponents()
        dateCompon.day = 1
        dateCompon.month = 1
        dateCompon.year = year
        dateCompon.timeZone = TimeZone.autoupdatingCurrent

        thisYearDate = calendar.date(from: dateCompon)!  //Same Calendar year as now
        oldDate = Date(timeIntervalSinceReferenceDate: 51_556_900)  // Aug 20, 2002
        yesterdayDate = Date(timeIntervalSinceNow: -86400)  // 24 hours previous
        todayDate = Date(timeIntervalSinceNow: -300)  // 5 minutes ago
    }

    @Test func smartDate_OldDateTest() async throws {
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: oldDate, isSmartDate: true)
                == oldDate
                .formatted(date: .abbreviated, time: .omitted)
        )
    }

    @Test func smartDate_ThisYearTest() async throws {
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: thisYearDate, isSmartDate: true)
                == thisYearDate
                .formatted(.dateTime.day().month(.abbreviated))
        )
    }

    @Test func smartDate_YesterdayTest() async throws {
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: yesterdayDate, isSmartDate: true) == "1 day ago")
    }

    @Test func smartDate_TodayTest() async throws {
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: todayDate, isSmartDate: true)
                == todayDate
                .formatted(date: .omitted, time: .shortened))
    }

    @Test func fullDate_AllDatesTest() async throws {
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: oldDate, isSmartDate: false) == oldDate.formatted(date: .numeric, time: .omitted))
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: thisYearDate, isSmartDate: false)
                == thisYearDate
                .formatted(date: .numeric, time: .omitted))
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: yesterdayDate, isSmartDate: false)
                == yesterdayDate
                .formatted(date: .numeric, time: .omitted))
        #expect(
            SmartDateFormatter()
                .dateFormatter(date: todayDate, isSmartDate: false)
                == todayDate
                .formatted(date: .numeric, time: .omitted))
    }

}
