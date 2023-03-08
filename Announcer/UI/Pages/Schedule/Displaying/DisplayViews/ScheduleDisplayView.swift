//
//  ScheduleDisplayView.swift
//  scheduleChopper
//
//  Created by Kai Quan Tay on 23/2/23.
//

import SwiftUI
import Chopper

struct ScheduleDisplayView: View {
    @ObservedObject var manager: ScheduleManager = .default
    @State var showInfo: Bool = false
    @State var showProvideSchedule: Bool = false

    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State var today: Date = .now

    @State var offsetAmount: Int = 0

    init() {
        let manager = ScheduleManager.default
        let today = Date.now
        self._day = State(wrappedValue: .init(week: manager.schedule.currentWeek%2 == 0 ? .even : .odd,
                                              day: today.weekday.dayOfWeek ?? .monday))
    }

    var body: some View {
        List {
            if manager.schedule.nowInRange {
                todayView
            } else {
                Section {
                    if manager.schedule.startDate > .now {
                        Text(
"Schedule starts on \(manager.schedule.startDate.formatted(date: .abbreviated, time: .omitted))"
)
                    } else {
                        Text(
"Schedule ended on \(manager.schedule.endDate.formatted(date: .abbreviated, time: .omitted))"
)
                    }
                    Button("Edit Schedule") {
                        showInfo = true
                    }
                }
            }

            Section {
                NavigationLink("Classes") {
                    ClassesDisplayView(schedule: manager.schedule)
                }
            }
        }
        .onReceive(timer) { _ in
            self.today = .now.addingTimeInterval(Double(offsetAmount * 60 * 20))
        }
        .navigationTitle("Schedule")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            if #available(iOS 16.0, *) {
                ScheduleInformationView(showProvideSchedule: $showProvideSchedule)
                    .presentationDetents([.medium, .large])
            } else {
                ScheduleInformationView(showProvideSchedule: $showProvideSchedule)
            }
        }
    }

    @State var compactTop: Bool = true

    @State var day: ScheduleDay
    var todayValue: ScheduleDay {
        let todayDay = today.weekday.dayOfWeek ?? .monday
        return ScheduleDay(week: manager.schedule.currentWeek%2 == 0 ? .even : .odd,
                           day: todayDay)
    }

    var isCurrentDay: Bool {
        // if the day of week is nil, its always false.
        guard today.weekday.dayOfWeek != nil else { return false }
        return day.description == todayValue.description
    }

    var todayView: some View {
        Section {
            DayPickerView(selection: $day, schedule: manager.schedule, today: todayValue)
                .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
            // leading things
            if indexOfCurrentSubject(day: day) > 3 && compactTop {
                HStack {
                    HStack {
                        ForEach(0..<min(3, indexOfCurrentSubject(day: day) - 3), id: \.self) { index in
                            manager.schedule.subjectsMatching(day: day.day, week: day.week)[index]
                                .displayColor
                                .frame(width: 10, height: 25)
                                .cornerRadius(5)
                        }
                    }
                    .mask(alignment: .leading) {
                        LinearGradient(stops: [
                            .init(color: .white, location: 0.2),
                            .init(color: .clear, location: 1)
                        ],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                        .frame(width: 50)
                    }
                    Text("\(indexOfCurrentSubject(day: day) - 3) subjects")
                        .padding(.horizontal, 5)
                        .font(.subheadline)
                    Spacer()
                }
                .onTapGesture {
                    withAnimation {
                        compactTop = false
                    }
                }
                .listRowInsets(.init(top: 5,
                                     leading: 8,
                                     bottom: 5,
                                     trailing: 8))
                .listRowSeparator(.hidden)
            }
            ForEach(Array(manager.schedule.subjectsMatching(day: day.day,
                                                            week: day.week).enumerated()),
                    id: \.0) { (index, subject) in
                if indexOfCurrentSubject(day: day) - index <= 3 || !compactTop {
                    viewForSubject(subject: subject)
                }
            }
            HStack {
                Button("Less") {
                    offsetAmount -= 1
                    self.today = .now.addingTimeInterval(Double(offsetAmount * 60 * 20))
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(offsetAmount), \(today.formatted(date: .omitted, time: .shortened))")
                Spacer()
                Button("More") {
                    offsetAmount += 1
                    self.today = .now.addingTimeInterval(Double(offsetAmount * 60 * 20))
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack {
                if today.weekday.dayOfWeek == nil {
                    Text("Next week: W\(manager.schedule.currentWeek+1)")
                } else {
                    Text("W\(manager.schedule.currentWeek), \(today.weekday.rawValue.firstLetterUppercase)")
                }
                Spacer()
                if indexOfCurrentSubject(day: day) > 3 {
                    Button {
                        withAnimation {
                            compactTop.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .rotationEffect(.degrees(compactTop ? 0 : 180))
                    }
                }
                NavigationLink(isActive: $showProvideSchedule) {
                    ProvideScheduleView(showProvideSuggestion: $showProvideSchedule)
                } label: {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    func viewForSubject(subject: Subject) -> some View {
        if #available(iOS 16.0, *) {
            SubjectDisplayView(today: today,
                               subject: subject,
                               allowShowingAsCurrent: isCurrentDay)
            .contextMenu {
                Button("Copy Details") {}
            } preview: {
                OtherSubjectInstancesView(schedule: manager.schedule, subClass: subject.subjectClass)
            }
            .overlay {
                NavigationLink {
                    OtherSubjectInstancesView(schedule: manager.schedule,
                                              subClass: subject.subjectClass,
                                              showVisualiser: true)
                } label: {}.opacity(0)
            }
            .listRowSeparator(.hidden)
        } else {
            SubjectDisplayView(today: today,
                               subject: subject,
                               allowShowingAsCurrent: isCurrentDay)
            .contextMenu {
                Button("Copy Details") {}
            }
            .overlay {
                NavigationLink {
                    OtherSubjectInstancesView(schedule: manager.schedule,
                                              subClass: subject.subjectClass,
                                              showVisualiser: true)
                } label: {}.opacity(0)
            }
            .listRowSeparator(.hidden)
        }
    }

    func indexOfCurrentSubject(day: ScheduleDay) -> Int {
        guard isCurrentDay else { return -1 }

        let subjects = manager.schedule.subjectsMatching(day: day.day, week: day.week)
        let todayTime = today.timePoint

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

struct Previews_ScheduleDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
