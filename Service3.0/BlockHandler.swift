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
    // резервация блока без значений. происходит первого числа каждого месяца
    class func reservationBlock(inService name: String) -> (result: Bool, notice: String?) {
        let date = Date.makePreviousPeriod()
        guard let fetchBlock = CoreDataHandler.fetchBlockForThisDate(date, inService: name) else {
            return (false, Notices.errorCoreData.rawValue)
        }
        guard fetchBlock.isEmpty else {
            return (false, Notices.blockAlreadyExist.rawValue)
        }
        guard CoreDataHandler.saveBlock(nameService: name, dateString: date) else {
            return (false, Notices.errorCoreData.rawValue)
        }
        return (true, nil)
    }
    
    
    class func inputMark(_ markString: String, inTheBlock block: Block) -> (result: Bool, notice: String?) {
        // перевод показателя из String в Double
        guard let mark = markString.transferToDouble() else {
            return (false, Notices.impossiblyStringToDouble.rawValue)
        }
        // получение кортежа с предпоследним блоком (если он есть?)
        let tuplLastBlock = identifyLastButOneBlock(inService: block.nameService!)
        guard let arrayLastBlock = tuplLastBlock.result else {
            return (false, tuplLastBlock.notice)
        }
        // проверка наличия в полученом результате блока
        // если предпоследнего нет, то выход из функции с сохранением введенного показателя
        guard !arrayLastBlock.isEmpty else {
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: nil) else {
                return (false, Notices.errorCoreData.rawValue)
            }
            return (true, Notices.thisFirstMark.rawValue)
        }
        let lastBlock = arrayLastBlock.first! // предпоследний блок
        // проверка на наличие показаний предыдущих периодов
        guard lastBlock.mark != 0 else {
            return (false, Notices.inputMarkPreviousPeriod.rawValue)
        }
        // вычисление объёма и проверка на его корректность
        let amount = block.mark - lastBlock.mark
        guard amount >= 0 else {return (false, Notices.incorrectMark.rawValue)}
        // проверка на наличие тарифов. Если тарифов нет - выход и сохранение имеющихся данных
        guard let tariffs = block.tariffInBlock else {
            return (true, Notices.noTariffs.rawValue)
        }
        // вычисление стоимости
        let val: Double
        guard tariffs.isAllotment else {
            // первый вариант: если тариф диеренциальный, то задействуется функция, которая высчитывает этот тариф
            guard let tuplTariffAndVals = getAllotmentVal(amount: amount, tariff: tariffs) else {
                return (false, Notices.needParametersForTariff.rawValue)
            }
            let tariffAmountVals = tuplTariffAndVals.tariffAmountVals
            val = tuplTariffAndVals.allVal
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: nil, newVal: val, isPay: nil, newTariffAmountVal: tariffAmountVals, newValDifference: nil) else {
                return (false, Notices.errorCoreData.rawValue)
            }
            return (true, nil)
        }
        // второй вариант: если тириф обычный, просто высчитывается стоимость
        let oneTariff = tariffs.tariffService
        val = amount * oneTariff
        guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: oneTariff, newVal: val, isPay: nil, newTariffAmountVal: nil, newValDifference: nil) else {
            return (false, Notices.errorCoreData.rawValue)
        }
        return (true, nil)
    }
    
    
    
    // определение предпоследнего блока, так как последний блок уже зарезервирован
    private class func identifyLastButOneBlock(inService name: String) -> (result: [Block]?, notice: String?) {
        guard let allBlocks = CoreDataHandler.fetchAllBlocks(inService: name) else { return (nil, Notices.errorCoreData.rawValue) }
        guard allBlocks.count > 1 else { return ([], nil) }
        var dateAndBlocks = [Date : Block]()
        for i in allBlocks {
            guard let date = i.date?.getDate() else {return (nil, Notices.impossiblyReadDateFromCD.rawValue)}
            dateAndBlocks[date] = i
        }
        dateAndBlocks.removeValue(forKey: dateAndBlocks.keys.max()!)
        let lastBlock = dateAndBlocks[dateAndBlocks.keys.max()!]!
        return ([lastBlock], nil)
    }
    
    
    
    private class func getAllotmentVal(amount: Double, tariff: Tariffs) -> (tariffAmountVals: [Double : [Double]], allVal: Double)?  {
        let parameterToTariff = (tariff.parameterToTariff as? [Double : Double])!
        var arrayParameters = parameterToTariff.keys.filter({$0 < amount})
        guard let maxArrayParameter = arrayParameters.max() else {return nil}
        let lastAmount = amount - arrayParameters.max()!
        let lastVall = lastAmount * parameterToTariff[maxArrayParameter]!
        var tariffAndVals = [parameterToTariff[maxArrayParameter]! : [lastAmount, lastVall]]
        for _ in 0..<arrayParameters.count {
            let max = arrayParameters.max()!
            let indexMax = arrayParameters.index(of: max)
            arrayParameters.remove(at: indexMax!)
            guard !arrayParameters.isEmpty else {
                let val = max * tariff.tariffService
                tariffAndVals[tariff.tariffService] = [max, val]
                break }
            let nextMax = arrayParameters.max()!
            let mediumAmount = max - nextMax
            let mediumTariff = parameterToTariff[nextMax]!
            let mediumVal = mediumAmount * mediumTariff
            tariffAndVals[mediumTariff] = [mediumAmount, mediumVal]
        }
        var allVal = Double()
        for i in tariffAndVals {
            allVal += i.value[1]
        }
        
        return (tariffAndVals, allVal)
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
}
