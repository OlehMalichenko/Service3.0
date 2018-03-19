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
    
    // MARK: Public
    // резервация блока без значений. происходит первого числа каждого месяца
    class func reservationBlock(inService name: String) -> (result: Bool, notice: String?) {
        let date = Date.makePreviousPeriod()
        guard let fetchBlock = CoreDataHandler.fetchBlockForThisDate(date, inService: name) else {
            return (false, Notices.errorCoreData.rawValue)
        }
        guard fetchBlock.isEmpty else {
            return (false, Notices.blockAlreadyExist.rawValue)
        }
        // сохранение блока. Присоединение последнего тарифа происходит на стадии saveBlock
        guard CoreDataHandler.saveBlock(nameService: name, dateString: date) else {
            return (false, Notices.errorCoreData.rawValue)
        }
        return (true, nil)
    }
    
    
    //основная функция по вводу показателя и расчета всех остальных параметров
    class func inputMark(_ markString: String, toService name: String, dateString: String) -> (result: Bool, notice: Notices?, block: Block?) {
        // поиск нужного блока
        guard let fetchingBlockInArray = CoreDataHandler.fetchBlockForThisDate(dateString, inService: name) else {
            return (false, Notices.errorCoreData, nil)
        }
        guard !fetchingBlockInArray.isEmpty else {
            return (false, Notices.noBlockforThisPeriod, nil)
        }
        let block = fetchingBlockInArray.first!
        // перевод показателя из String в Double
        guard let mark = markString.transferToDouble() else {
            return (false, Notices.impossiblyStringToDouble, nil)
        }
        // получение кортежа с предпоследним блоком (если он есть?)
        let tuplLastBlock = identifyLastButOneBlock(inService: block.nameService!)
        guard let arrayLastBlock = tuplLastBlock.result else {
            return (false, tuplLastBlock.notice, nil)
        }
        // проверка наличия в полученом результате блока
        // если предпоследнего нет, то выход из функции с сохранением введенного показателя
        guard !arrayLastBlock.isEmpty else {
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: nil, newTariffInBlock: nil) else {
                return (false, Notices.errorCoreData, nil)
            }
            return (true, Notices.thisFirstMark, block)
        }
        let lastBlock = arrayLastBlock.first! // предпоследний блок
        // проверка на наличие показаний предыдущих периодов
        guard lastBlock.mark != 0 else {
            return (false, Notices.inputMarkPreviousPeriod, nil)
        }
        // вычисление объёма и проверка на его корректность
        let amount = block.mark - lastBlock.mark
        guard amount >= 0 else {return (false, Notices.incorrectMark, nil)}
        // проверка на наличие тарифов. Если тарифов нет - выход и сохранение имеющихся данных
        guard let tariffs = block.tariffInBlock else {
            return (true, Notices.noTariffs, block)
        }
        // вычисление стоимости
        let val: Double
        guard tariffs.isAllotment else {
            // первый вариант: если тариф диеренциальный, то задействуется функция, которая высчитывает этот тариф
            guard let tuplTariffAndVals = getAllotmentVal(amount: amount, tariff: tariffs) else {
                return (false, Notices.needParametersForTariff, nil)
            }
            let tariffAmountVals = tuplTariffAndVals.tariffAmountVals
            val = tuplTariffAndVals.allVal
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: nil, newVal: val, isPay: nil, newTariffAmountVal: tariffAmountVals, newValDifference: nil, newTariffInBlock: nil) else {
                return (false, Notices.errorCoreData, nil)
            }
            return (true, nil, block)
        }
        // второй вариант: если тириф обычный, просто высчитывается стоимость
        let oneTariff = tariffs.tariffService
        val = amount * oneTariff
        guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: oneTariff, newVal: val, isPay: nil, newTariffAmountVal: nil, newValDifference: nil, newTariffInBlock: nil) else {
            return (false, Notices.errorCoreData, nil)
        }
        return (true, nil, block)
    }
    
    // вывод всех параметров блока после функции inputMark, при этом учитываются разные результаты паботы функции
    class func outputParametersFromBlock(tupl: (result: Bool, notice: Notices?, block: Block?)) -> [Properties : String] {
        var result = [Properties : String]()
        switch tupl {
        case (true, _, _) where tupl.notice == nil && tupl.block != nil:
            result = parsedBlock(tupl.block!)
        case (true, _, _) where tupl.notice != nil && tupl.block != nil:
            result = parsedBlock(tupl.block!)
            result[.shortProperties] = tupl.notice!.rawValue
        case (false, _, nil) where tupl.notice != nil:
            result[.errorComlete] = tupl.notice!.rawValue
        default: break
        }
        return result
    }
    
    
    // получение словаря [Date : Block]
    class func getDictionaryDateBlock(inService name: String) -> [Date : Block]? {
        var result = [Date : Block]()
        guard let blockArray = CoreDataHandler.fetchAllBlocks(inService: name) else {
            return nil
        }
        guard !blockArray.isEmpty else {
            return nil
        }
        for i in blockArray {
            let date = i.date?.getDate()
            result[date!] = i
        }
        return result
    }
    
    
    // MARK: - Private
    // непосредственно вывод показателей из блока в формате строки
    private class func parsedBlock(_ block: Block) -> [Properties : String] {
        var result = [Properties : String]()
        result[.name] = block.nameService!
        result[.date] = block.date!
        if block.mark != 0 { result[.mark] = block.mark.roundedToTwoNumbers().description }
        if block.amount != 0 { result[.amount] = block.amount.roundedToTwoNumbers().description }
        if block.tariffInBlock != nil {
            if block.oneTariff != 0 {
                result[.oneTariff] = block.oneTariff.roundedToTwoNumbers().description
            }
            if block.tariffInBlock!.isAllotment {
                if block.tariffAmountVal != nil {
                    let tav = block.tariffAmountVal as! [Double: [Double]]
                    result[.tariffAmountVal] = stringFromDictionary(tav)
                }
                if block.val != 0 { result[.val] = block.val.roundedToTwoNumbers().description }
            } else {
              if block.val != 0 { result[.val] = block.val.roundedToTwoNumbers().description }
            }
        }
        if block.isPay {
            result[.isPay] = Notices.isPay.rawValue
        } else {
            result[.isPay] = Notices.isNotPay.rawValue
        }
        return result
    }

    
    // определение предпоследнего блока, так как последний блок уже зарезервирован
    private class func identifyLastButOneBlock(inService name: String) -> (result: [Block]?, notice: Notices?) {
        guard let allBlocks = CoreDataHandler.fetchAllBlocks(inService: name) else { return (nil, Notices.errorCoreData) }
        guard allBlocks.count > 1 else { return ([], nil) }
        var dateAndBlocks = [Date : Block]()
        for i in allBlocks {
            guard let date = i.date?.getDate() else {return (nil, Notices.impossiblyReadDateFromCD)}
            dateAndBlocks[date] = i
        }
        dateAndBlocks.removeValue(forKey: dateAndBlocks.keys.max()!)
        let lastBlock = dateAndBlocks[dateAndBlocks.keys.max()!]!
        return ([lastBlock], nil)
    }
    
    
    
    // определение стоимости с диференциальным тарифом
    class func getAllotmentVal(amount: Double, tariff: Tariffs) -> (tariffAmountVals: [Double : [Double]], allVal: Double)?  {
        let parameterToTariff = (tariff.parameterToTariff as? [Double : Double])!
        var arrayParameters = parameterToTariff.keys.filter({$0 < amount})
        guard let maxArrayParameter = arrayParameters.max() else {
            return nil
        }
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
    
    
    // перевод массива в строку
    private class func stringFromArray(_ array: [Double]) -> String {
        var result = ""
        var counter = 0
        for i in array {
            let str = array.count == counter ? i.description + " ." : i.description + " ,"
            result += str
            counter += 1
        }
        return result
    }
    
    // перевод словаря tariffAmountVal в строку
    private class func stringFromDictionary(_ dictionary: [Double : [Double]]) -> String {
       var result = ""
        for i in dictionary {
            let forTariff = "По тарифу: \(i.key.description)\n"
            let usedAmount = "\tOбъём: \(i.value.first!.roundedToTwoNumbers().description)\n"
            let valForAmount = "\tСтоимость: \(i.value.last!.roundedToTwoNumbers().description)\n"
            let oneIteration = forTariff + usedAmount + valForAmount
            result += oneIteration
        }
        return result
    }
}
