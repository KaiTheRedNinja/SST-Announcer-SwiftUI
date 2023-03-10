//
//  TimeTableProtocol.swift
//  Announcer
//
//  Created by Kai Quan Tay on 7/3/23.
//

import SwiftUI
import Chopper

protocol TimeTableProtocol: View {
    var manager: ScheduleManager { get }
    var today: Date { get }
}

extension TimeTableProtocol {

    var todayValue: ScheduleDay {
        let todayDay = today.weekday.dayOfWeek ?? .monday
        return ScheduleDay(week: manager.currentSchedule.currentWeek%2 == 0 ? .even : .odd,
                           day: todayDay)
    }

    var todaySubjects: [Subject] {
        manager.currentSchedule.subjectsMatching(day: todayValue.day,
                                                 week: todayValue.week)
    }

    // eg. if there are five subjects and subject 0 is the current one, subject 0, 1, and 2 will be shown.
    // 3 and 4 will be hidden.
    // if subject 2 is the current one, subject 2, 3, and 4 will be shown. None are hidden.
    var bottomCompactedSubjects: Int {
        max(0, todaySubjects.count - (indexOfCurrentSubject()+3))
    }

    func indexOfCurrentSubject() -> Int {
        let todayTime = today.timePoint
        let subjects = todaySubjects

        // during available subjects
        if let index = subjects.firstIndex(where: { $0.contains(time: todayTime) }) {
            return index
        }

        // before start
        if let start = subjects.first?.timeRange.lowerBound, start > todayTime {
            return -1
        }

        // after end
        if let end = subjects.last?.timeRange.upperBound, end < todayTime {
            return subjects.count
        }

        // default to before start
        return -1
    }
}
