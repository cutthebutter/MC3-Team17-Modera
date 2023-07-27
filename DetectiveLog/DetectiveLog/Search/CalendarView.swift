//
//  CalenderView.swift
//  DetectiveLog
//
//  Created by semini on 2023/07/26.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel = SearchTestViewModel()
    @State private var month: Date = Date()
    @Binding var clickedCurrentMonthDates: Date?
    @State private var isMonthChange = false
    @Binding var showCalendar : Bool

    
    var body: some View {
        VStack {
            yearMonthHeaderView
                .padding(.vertical)
            Spacer()
            if isMonthChange {
                MoveYearMonthPicker(month: $month, isMonthChange: $isMonthChange, viewModel: SearchTestViewModel())
            } else {
                calendarView
            }
            Spacer()
            
        }
    }
    
    // MARK: - 연월 표시 헤더 뷰
    var yearMonthHeaderView: some View {
        HStack(alignment: .center, spacing: 20) {
            
            Button {
                isMonthChange.toggle()
            } label: {
                Text(month, formatter: Self.calendarHeaderDateFormatter)
                    .font(.title2)
                    .fontWeight(.medium)
                Image(systemName: isMonthChange ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.caption2)
                
            }.foregroundColor(Color.black)
                .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            if !isMonthChange {
                Button{
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(canMoveToPreviousMonth() ? .black : . gray)
                }
                .disabled(!canMoveToPreviousMonth())
                
                Button{
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(canMoveToNextMonth() ? .black : .gray)
                }
                .disabled(!canMoveToNextMonth())
            }
            
        }
        .padding(.horizontal)
    }
    
    var calendarView : some View {
        VStack{
            dayView
            calendarGridView
        }
    }
    
    var dayView : some View {
        HStack {
            ForEach(Self.koreanWeekdaySymbols.indices, id: \.self) { symbol in
                Text(Self.koreanWeekdaySymbols[symbol])
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - 날짜 그리드 뷰
    var calendarGridView: some View {
//        @State var dateTakingMemoList = viewModel.logMemoDates()
        let daysInMonth: Int = numberOfDays(in: month)
        let firstWeekday: Int = firstWeekdayOfMonth(in: month) - 1
        let columns = Array(repeating: GridItem(), count: 7)
        let range = -firstWeekday ..< daysInMonth
        let indices = Array(range)
        
        // 날짜 형식 지정자
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return LazyVGrid(columns: columns) {
            ForEach(indices, id: \.self) { index in
                Group {
                    if index > -1 && index < daysInMonth {
                        let date : Date = getDate(for: index)
                        let dateString : String = dateFormatter.string(from: date)  // 새 변수
                        let day : Int = Calendar.current.component(.day, from: date)
                        let clicked : Bool = clickedCurrentMonthDates == date
                        let isToday : Bool = date.formattedCalendarDayDate == today.formattedCalendarDayDate
                        let isMemoInDate = viewModel.logMemoDates.contains(dateString) // 수정된 부분

//                        CellView(day: day, clicked: clicked, isToday: isToday, isMemoinDate: isMemoInDate)
//                            .disabled(!isMemoInDate)
                        
                        Button(action: {
                            if isMemoInDate {
                                clickedCurrentMonthDates = date
                                print("@Log clickedCurrentMonthDates: \(clickedCurrentMonthDates)")
                                showCalendar = false
                            }
                        }) {
                            CellView(day: day, clicked: clicked, isToday: isToday, isMemoinDate: isMemoInDate)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    } else if Calendar.current.date(
                        byAdding: .day,
                        value: index,
                        to: previousMonth()
                    ) != nil {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundColor(Color.clear)
                    }
                }
                .onTapGesture {
                    if 0 <= index && index < daysInMonth {
                        let date = getDate(for: index)
                        clickedCurrentMonthDates = date
                    }
                }
            }
        }
    }
}

// MARK: - 일자 셀 뷰
private struct CellView: View {
    private var day: Int
    private var clicked: Bool
    private var isToday: Bool
    private var isMemoinDate: Bool
    private var textColor: Color {
        if clicked || isToday {
            return Color.white
        } else if isMemoinDate{
            return Color.black
        } else {
            return Color.gray.opacity(0.5)
        }
    }
    private var backgroundColor: Color {
        if clicked {
            return Color.black
        } else if isToday {
            return Color.gray
        } else {
            return Color.white
        }
    }
    
    fileprivate init(
        day: Int,
        clicked: Bool = false,
        isToday: Bool = false,
        isMemoinDate: Bool = true
//        isCurrentMonthDay: Bool = true
    ) {
        self.day = day
        self.clicked = clicked
        self.isToday = isToday
        self.isMemoinDate = isMemoinDate
//        self.isCurrentMonthDay = isCurrentMonthDay
    }
    
    ///기본적으로 캘린더가 동그라미로 구성
    fileprivate var body: some View {
        VStack {
            Circle()
                .fill(backgroundColor)
                .overlay(Text(String(day)))
                .foregroundColor(textColor)
                .frame(height: 30)
        }
    }
}

extension CalendarView {
    var today: Date {
        let now = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        return Calendar.current.date(from: components)!
    }
    
    static let calendarHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY년 M월"
        return formatter
    }()
    
    static var koreanWeekdaySymbols: [String] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar.shortWeekdaySymbols
    }
    
    
    static let weekdaySymbols: [String] = Calendar.current.shortWeekdaySymbols
    
    /// 특정 해당 날짜
    func getDate(for index: Int) -> Date {
        let calendar = Calendar.current
        guard let firstDayOfMonth = calendar.date(
            from: DateComponents(
                year: calendar.component(.year, from: month),
                month: calendar.component(.month, from: month),
                day: 1
            )
        ) else {
            return Date()
        }
        
        var dateComponents = DateComponents()
        dateComponents.day = index
        
        let timeZone = TimeZone.current
        let offset = Double(timeZone.secondsFromGMT(for: firstDayOfMonth))
        dateComponents.second = Int(offset)
        
        let date = calendar.date(byAdding: dateComponents, to: firstDayOfMonth) ?? Date()
        return date
    }
    
    /// 해당 월에 존재하는 일자 수
    func numberOfDays(in date: Date) -> Int {
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    /// 해당 월의 첫 날짜가 갖는 해당 주의 몇번째 요일
    func firstWeekdayOfMonth(in date: Date) -> Int {
        let components = Calendar.current.dateComponents([.year, .month], from: date)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        
        return Calendar.current.component(.weekday, from: firstDayOfMonth)
    }
    
    /// 이전 월 마지막 일자
    func previousMonth() -> Date {
        let components = Calendar.current.dateComponents([.year, .month], from: month)
        let firstDayOfMonth = Calendar.current.date(from: components)!
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        
        return previousMonth
    }
    
    /// 월 변경
    func changeMonth(by value: Int) {
        self.month = adjustedMonth(by: value)
    }
    
    /// 이전 월로 이동 가능한지 확인
    func canMoveToPreviousMonth() -> Bool {
        let targetDate = viewModel.logMemoList.first?.date ?? Date()
        if adjustedMonth(by: -1) < (targetDate-2) {
            return false
        }
        return true
    }
    
    /// 다음 월로 이동 가능한지 확인
    func canMoveToNextMonth() -> Bool {
        let targetDate = Date()
        if adjustedMonth(by: 1) > targetDate {
            return false
        }
        return true
    }
    
    /// 변경하려는 월 반환
    func adjustedMonth(by value: Int) -> Date {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: month) {
            return newMonth
        }
        return month
    }
}

extension Date {
    static let calendarDayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy dd"
        return formatter
    }()
    
    var formattedCalendarDayDate: String {
        return Date.calendarDayDateFormatter.string(from: self)
    }
}

//struct CalenderView_Previews: PreviewProvider {
//    static var previews: some View {
//        CalendarView()
//    }
//}
