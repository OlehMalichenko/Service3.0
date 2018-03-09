//
//  BlockHandler.swift
//  Service3.0
//
//  Created by OlehMalichenko on 08.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import UIKit
import CoreData

class BlockHandler: NSObject {
    
    class func inputMark(_ markString: String, for nameService: String, to dateStr: String) -> [Properties : String] {
        // проверка на возможность вывести Double из String
        guard let mark = markString.transferToDouble() else {
            return [Properties.noError : Notices.canNotDetermineStringToDouble.rawValue]
        }
        // результат для возврата
        var result = [Properties : String]()
        // данные, которые будут формироваться в процессе работы функции
        var previoceMark = Double() // предыдущий показатель
        var amount = Double() // объём услуг
        var val = Double() // стоимость услуг
        var tariffForThisAmount = [Double]()// массив тарифов для определенного объёма (их может быть несколько)
        // запись в результат уже имеющихся данных
        result[.name] = nameService
        result[.date] = dateStr
        result[.mark] = markString
        // получение массива блоков по имени сервиса
        guard let blocksArray = CoreDataHandler.fetchAllBlocks(inService: nameService) else {
            return [Properties.noError : Notices.errorInCoreData.rawValue]
        }
        // проверка на наличие этих блоков
        // если предыдущих блоков нет, то к результату добавляется сooбщение о первом вводе
        // затем следует сохранение блока
        guard !blocksArray.isEmpty else {
            result[Properties.incomplete] = Notices.firstMark.rawValue
            if CoreDataHandler.saveBlock(nameService: nameService, date: dateStr, mark: mark, amount: nil, val: nil, tariffs: nil, valAllotment: nil) {
                return result
            } else {
                return [Properties.noError : Notices.errorInCoreData.rawValue]
            }
        }
        /* определение объёма услуг*/
        let lastBlock = getLastBlock(blockArray: blocksArray) // нахождение последнего блока
        previoceMark = (lastBlock.first?.value.mark)! // определение последнего показателя
        amount = mark - previoceMark // определение объёма услуг
        // если объём услуг является отрицательным числом, возвращается уведомление о некорректном показателе
        guard amount >= 0 else {
            return [Properties.noError : Notices.incorrectMark.rawValue]
        }
        // включение в результат объёма
        result[.amount] = amount.roundedToTwoNumbers().description
        // выборка всех всех тарифов по сервису и проверка на их наличие
        guard let fetchTariffs = CoreDataHandler.fetchAllTariffs(inService: nameService) else {
            return [Properties.noError : Notices.errorInCoreData.rawValue]
        }
        guard !fetchTariffs.isEmpty else {
            result[.incomplete] = Notices.tariffIsEmpty.rawValue
            if CoreDataHandler.saveBlock(nameService: nameService, date: dateStr, mark: mark, amount: amount, val: nil, tariffs: nil, valAllotment: nil ) {
                return result
            } else {
                return [Properties.noError : Notices.errorInCoreData.rawValue]
            }
        }
        let dictionaryLastTariff = getLastTatiff(tariffArray: fetchTariffs).first!
        let lastDateTariff = dictionaryLastTariff.key
        let lastTariff = dictionaryLastTariff.value
        let startDateAmount = (lastBlock.first?.key)!
        guard startDateAmount >= lastDateTariff else {
            guard let arrayAllTarifs = CoreDataHandler.fetchAllTariffs(inService: nameService) else {
                return [Properties.noError : Notices.errorInCoreData.rawValue]
            }
            let tariffsDI = getTariffDI(tariffArray: arrayAllTarifs)
            let amountDI = DateInterval(start: (lastBlock.first?.key)!, end: dateStr.getDate()!)
            let amountPerDay = amount / amountDI.days()
            
        
        }
        
        let tariffForThis = lastTariff.tariffService
        val = amount * tariffForThis
        result[.tariff] = tariffForThis.description
        result[.val] = val.description
        if CoreDataHandler.saveBlock(nameService: nameService, date: dateStr, mark: mark, amount: amount, val: val, tariffs: [tariffForThis], valAllotment: nil ) {
            return result
        } else {
            return [Properties.noError : Notices.errorInCoreData.rawValue]
        }
    }
    
    
    // формирование общей стоимости и тарифов, которые использовались для такого формирования (если используется несколько тарифов)
    private class func costingBySeveralTariffs(amountDI: DateInterval, tariffDI: [DateInterval : Tariffs], amountPerDay: Double) -> (tariffs: [Double], val: Double, notice: String?) {
        
        var resultTariffs = [Double]()
        var resultVal = Double()
        var daysInTariff = Double()
        
        for i in tariffDI {
            guard let intersection = amountDI.intersection(with: i.key) else {continue}
            let valFromIntersection = (amountPerDay * intersection.days()) * i.value.tariffService
            resultVal += valFromIntersection
            resultTariffs.append(i.value.tariffService)
            daysInTariff += intersection.days()
        }
        guard amountDI.days() == daysInTariff else {
            let differenceDays = (Int(amountDI.days() - daysInTariff)).description
            return (resultTariffs, resultVal, Notices.tariffDoesNotCover.rawValue + differenceDays + " дней")
        }
        return (resultTariffs, resultVal, nil)
    }
    
    
    private class func transformStringFromArray(_ array: [Double]) -> String {
        var result = ""
        var counter = 0
        for i in array {
            let str = array.count == counter ? i.description + " ." : i.description + " ,"
            result += str
            counter += 1
        }
        return result
    }
    
    
    private class func transformStringFromDictionary(_ dictionary: [Double : Double]) -> String {
        var result = ""
        for i in dictionary {
            let str = "\(i.key.description) - \(i.value.description)  "
            result += str
        }
        return result
    }
    
    
    private class func getAllotmentVal(amount: Double, tariff: Tariffs) -> (amountAndVal: [Double : Double], allVal: Double) {
        var amountAndVal = [Double : Double]()
        let valStandart = tariff.allotmentParameter * tariff.tariffService
        amountAndVal[tariff.allotmentParameter] = valStandart
        let amountAfter = amount - tariff.allotmentParameter
        let valAfter = amountAfter * tariff.tariffAfter
        amountAndVal[amountAfter] = valAfter
        let allVal = valStandart + valAfter
        return (amountAndVal, allVal)
    }
    
    
    private class func getTariffDI(tariffArray: [Tariffs]) -> [DateInterval : Tariffs] {
        var dateTariffs = [Date : Tariffs]()
        for i in tariffArray {
            let dateInTariff = (i.dateTariff)!.getDate()
            dateTariffs[dateInTariff!] = i
        }
        var result = [DateInterval : Tariffs]()
        for _ in 0..<dateTariffs.count {
            let start = dateTariffs.keys.min()
            let index = dateTariffs.index(forKey: start!)
            dateTariffs.remove(at: index!)
            let end = dateTariffs.isEmpty ? start?.addingTimeInterval(315360000) : dateTariffs.keys.min()
            let dateInterval = DateInterval(start: start!, end: end!)
            result[dateInterval] = dateTariffs[start!]
        }
        return result
    }
    
    
    private class func getLastTatiff(tariffArray: [Tariffs]) -> [Date : Tariffs] {
        var dateTariffs = [Date : Tariffs]()
        for i in tariffArray {
            let dateInTariff = (i.dateTariff)!.getDate()
            dateTariffs[dateInTariff!] = i
        }
        var lastTariff = [Date : Tariffs]()
        let lastDate = dateTariffs.keys.max()!
        lastTariff[lastDate] = dateTariffs[lastDate]
        return lastTariff
    }
    
    
    private class func getLastBlock(blockArray: [Block]) -> [Date : Block] {
        var dateBlocks = [Date : Block]()
        for i in blockArray {
            let dateInBlock = (i.date)!.getDate()
            dateBlocks[dateInBlock!] = i
        }
        var lastBlock = [Date : Block]()
        let lastDate = dateBlocks.keys.max()!
        lastBlock[lastDate] = dateBlocks[lastDate]
        return lastBlock
    }
}
