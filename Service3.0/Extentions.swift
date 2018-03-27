//
//  Extentions.swift
//  Service3.0
//
//  Created by OlehMalichenko on 08.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import Foundation
import CoreData

// для преобразования строки в Double и формирования даты
extension String {
    func transferToDouble() -> Double? {
        guard let double = Double(self) else {return nil}
        return double
    }
    
    func getDate() -> Date? {
        let formater = DateFormatter()
        formater.dateFormat = "MMMM, yy"
        guard let date = formater.date(from: self) else {
            return nil
        }
        return date
    }
}

// для перевода даты в строку определенного формата
extension Date {
    func dateToString() -> String {
        let formater = DateFormatter()
        formater.dateFormat = "MMMM, yy"
        return formater.string(from: self)
    }
}

// создание даты, предыдущей (на один месяц) от той, когда вводятся данные (дата выводится как месяц и год)
extension Date {
    static func makePreviousPeriod() -> String {
        let calendar = Calendar.current
        let formater = DateFormatter()
        formater.dateFormat = "MMMM, yy"
        let datePeriod = calendar.date(byAdding: .month, value: -1, to: Date())
        let result = formater.string(from: datePeriod!)
        return result
    }
}


// расширение для отображения колличества знаков после запятой в Double
extension Double {
    func roundedToTwoNumbers() -> Double {
        let divisor = pow(10.0, Double(2))
        return (self * divisor).rounded() / divisor
    }
}

// показ дней и часов в интервале
extension DateInterval {
    func days()-> Double {
        return (self.duration/60/60/24).rounded()
    }
    func hours()-> Double {
        return (self.duration/60/60).rounded()
    }
}
