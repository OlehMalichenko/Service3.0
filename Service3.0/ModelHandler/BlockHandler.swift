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
    // резервация блока без значений.
    class func reservationBlock(inService name: String, dateString: String) -> (result: Bool, notice: Notices?) {
        // получение даты резервации блока
        guard let date = dateString.getDate() else {return (false, Notices.impossiblyStringToDate)}
        // получение предыдущего месяца от даты резервации
        let previousDate = Date.makePreviousPeriod(forDate: date)
        guard let fetchBlock = CoreDataHandler.fetchBlockForThisDate(previousDate, inService: name) else {
            return (false, Notices.errorCoreData)
        }
        guard fetchBlock.isEmpty else {
            return (true, Notices.blockAlreadyExist)
        }
        // сохранение блока. Присоединение последнего тарифа происходит на стадии saveBlock
        guard CoreDataHandler.saveBlock(nameService: name, dateString: previousDate) else {
            return (false, Notices.errorCoreData)
        }
        let recReservation = reservationBlock(inService: name, dateString: previousDate)
        if !recReservation.result {
            
        }
        return (true, nil)
    }
    
    
    
    //основная функция по вводу показателя и расчета всех остальных параметров
    class func inputMark(_ markString: String, toService name: String, dateString: String) -> (result: Bool, notice: Notices?, block: Block?) {
        // поиск нужного блока (он уже заранее зарезервирован фуекцией reservationBlock)
        guard let fetchingBlockInArray = CoreDataHandler.fetchBlockForThisDate(dateString, inService: name) else {
            return (false, Notices.errorCoreData, nil)
        }
        guard fetchingBlockInArray.count == 1 else {
            return (false, Notices.noBlockforThisPeriod, nil)
        }
        let block = fetchingBlockInArray.first!
        // перевод показателя из String в Double
        guard let mark = markString.transferToDouble() else {
            return (false, Notices.impossiblyStringToDouble, nil)
        }
        // получение кортежа с предпоследним блоком (если он есть?)
        // предпоследний, потому что последний уже заразервирован
        let tuplLastBlock = identifyLastButOneBlock(inService: block.nameService!, forDate: dateString)
        guard let arrayLastBlock = tuplLastBlock.result else {
            return (false, tuplLastBlock.notice, nil)
        }
        // проверка наличия в полученом результате блока
        // если предпоследнего нет, то выход из функции с сохранением введенного показателя и сообщением о том, что это первый показатель
        guard !arrayLastBlock.isEmpty else {
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: nil, newForPay: nil, newTariffInBlock: nil) else {
                return (false, Notices.errorCoreData, nil)
            }
            return (true, Notices.thisFirstMark, block)
        }
        let lastBlock = arrayLastBlock.first! // предпоследний блок
        // проверка на наличие показаний предыдущих периодов. Если нет - то сохранение не проводится
        guard lastBlock.mark != 0 else {
            return (false, Notices.inputMarkPreviousPeriod, nil)
        }
        // вычисление объёма и проверка на его корректность (на случай, если объём отрицательный)
        let amount = mark - lastBlock.mark
        guard amount >= 0 else {return (false, Notices.incorrectMark, nil)}
        // проверка на наличие тарифов. Если тарифов нет - выход и сохранение имеющихся данных
        guard let tariffs = block.tariffInBlock else {
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: nil, newForPay: nil, newTariffInBlock: nil) else {
                return (false, Notices.errorCoreData, nil)
            }
            return (true, Notices.noTariffs, block)
        }
        // вычисление стоимости
        let val: Double
        let forPay: Double
        let valDifference: Double
        let isPay: Bool
        guard tariffs.parameterToTariff == nil else {
            // 1. первый вариант: если тариф диеренциальный, то задействуется функция, которая высчитывает этот тариф
            guard let tuplTariffAndVals = getAllotmentVal(amount: amount, tariff: tariffs) else {
                guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: nil, newForPay: nil, newTariffInBlock: nil) else {
                    return (false, Notices.errorCoreData, nil)
                }
                return (false, Notices.needParametersForTariff, block) // если параметры дифТарифа не установлены - сохранение имеющихся данных
            }
            let tariffAmountVals = tuplTariffAndVals.tariffAmountVals
            val = tuplTariffAndVals.allVal
            // сбор данных о переплатах (минусовой forPay)
            guard let negativePayInLastPeriods = checkBlocksWithNegativeForPay(inService: name) else {
                return (false, Notices.errorCoreData, nil)
            }
            forPay = val + negativePayInLastPeriods // добавление (минусование от стоимости)
            valDifference = negativePayInLastPeriods != 0 ? -(negativePayInLastPeriods) : 0 // буфер оплаченной части
            isPay = forPay > 0 ? false : true
            guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: tariffs.tariffService, newVal: val, isPay: isPay, newTariffAmountVal: tariffAmountVals, newValDifference: valDifference, newForPay: forPay, newTariffInBlock: nil) else {
                return (false, Notices.errorCoreData, nil)
            }
            // обновление данных общих неоплаченных сумм (при первом варианте)
            let tuplUpdateSum = ServiceHandler.updateSumInService(name)
            guard tuplUpdateSum.result else {
                return(true, tuplUpdateSum.notice, block)
            }
            return (true, nil, block)
        }
        // 2. второй вариант: если тириф обычный, просто высчитывается стоимость
        let oneTariff = tariffs.tariffService
        val = amount * oneTariff
        // если оплата предыдущего блока была минусовой - оплата настоящего блока минусуется
        // сбор данных о переплатах (минусовой forPay)
        guard let negativePayInLastPeriods = checkBlocksWithNegativeForPay(inService: name) else {
            return (false, Notices.errorCoreData, nil)
        }
        forPay = val + negativePayInLastPeriods // добавление (минусование от стоимости)
        valDifference = negativePayInLastPeriods != 0 ? -(negativePayInLastPeriods) : 0 // буфер оплаченной части
        isPay = forPay > 0 ? false : true // состояние оплаты в зависимости от положительного или отрицательного числа
        guard CoreDataHandler.updateBlock(block, newMark: mark, newAmount: amount, newOneTariff: oneTariff, newVal: val, isPay: isPay, newTariffAmountVal: nil, newValDifference: valDifference, newForPay: forPay, newTariffInBlock: nil) else {
            return (false, Notices.errorCoreData, nil)
        }
        // обновление данных общих неоплаченных сумм (при втором варианте)
        let tuplUpdateSum = ServiceHandler.updateSumInService(name)
        guard tuplUpdateSum.result else {
            return(true, tuplUpdateSum.notice, block)
        }
        return (true, nil, block)
    }
    
    
    
    // проверка блоков, которые переплачены (то есть минусовое значение к оплате) и вывод всех минусовых оплат "на возврат"
    // параллельно - обнуление значений к оплате и отъём разницы в буфере + сохранение измененного блока
    class func checkBlocksWithNegativeForPay(inService name: String) -> Double? {
        guard let blocksArray = CoreDataHandler.fetchIsPayBlocksWithNegativeForPay(inService: name) else {
            return nil
        }
        var result: Double = 0
        for i in blocksArray {
            result += i.forPay
            let valDifference = i.valDifference + i.forPay
            guard CoreDataHandler.updateBlock(i, newMark: nil, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: valDifference, newForPay: 0, newTariffInBlock: nil) else { return nil }
        }
        return result
    }
    
    
    
    // вывод всех параметров блока после функции inputMark, при этом учитываются разные результаты паботы функции
    class func outputBlockAfterInput(tupl: (result: Bool, notice: Notices?, block: Block?)) -> [Properties : String] {
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
    
    
    
    // вывод всех параметров блока при запросе их из View
    class func outputBlock(forService name: String, andDate dateString: String) -> [Properties : String] {
        var result = [Properties : String]()
        guard let blockArray = CoreDataHandler.fetchBlockForThisDate(dateString, inService: name) else {
            return [Properties.errorComlete : Notices.errorCoreData.rawValue]
        }
        guard !blockArray.isEmpty else {
            return [Properties.errorComlete : Notices.noBlockforThisPeriod.rawValue]
        }
        let block = blockArray.first!
        result = parsedBlock(block)
        return result
    }
    
    
    
    // вывод всех блоков для View
    class func outputAllBlocks(forService name: String) -> [[Properties : String]] {
        var result = [[Properties : String]]()
        guard let allBlocksArray = CoreDataHandler.fetchAllBlocks(inService: name) else {
           return [[Properties.errorComlete : Notices.errorCoreData.rawValue]]
        }
        guard !allBlocksArray.isEmpty else {
            return [[Properties.errorComlete : Notices.noBlocks.rawValue]]
        }
        var parsetedOneBlock = [Properties : String]()
        for i in allBlocksArray {
            parsetedOneBlock = parsedBlock(i)
            result.append(parsetedOneBlock)
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
            if block.tariffInBlock!.parameterToTariff != nil {
                if block.tariffAmountVal != nil {
                    let tav = block.tariffAmountVal as! [Double: [Double]]
                    result[.tariffAmountVal] = stringFromDictionary(tav)
                }
                if block.val != 0 { result[.val] = block.val.roundedToTwoNumbers().description }
            } else {
              if block.val != 0 { result[.val] = block.val.roundedToTwoNumbers().description }
            }
        }
    if block.forPay != 0 { result[.forPay] = block.forPay.roundedToTwoNumbers().description }
        if block.isPay {
            result[.isPay] = Notices.isPay.rawValue
        } else {
            result[.isPay] = Notices.isNotPay.rawValue
        }
        return result
    }

    
    
    // определение предпоследнего блока, так как последний блок уже зарезервирован
    private class func identifyLastButOneBlock(inService name: String, forDate dateString: String) -> (result: [Block]?, notice: Notices?) {
        guard let dateExistBlock = dateString.getDate() else {return (nil, Notices.impossiblyStringToDate)}
        guard let allBlocks = CoreDataHandler.fetchAllBlocks(inService: name) else { return (nil, Notices.errorCoreData) }
        guard allBlocks.count > 1 else { return ([], nil) }
        var dateAndBlocks = [Date : Block]()
        for i in allBlocks {
            guard let date = i.date?.getDate() else {return (nil, Notices.impossiblyReadDateFromCD)}
            if date < dateExistBlock {
                dateAndBlocks[date] = i
            }
        }
        guard dateAndBlocks.count >= 1 else {return ([], Notices.thisFirstMark)}
        let lastBlock = dateAndBlocks[dateAndBlocks.keys.max()!]!
        return ([lastBlock], nil)
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
    class func stringFromDictionary(_ dictionary: [Double : [Double]]) -> String {
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
