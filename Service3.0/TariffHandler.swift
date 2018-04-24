//
//  TariffHandler.swift
//  Service3.0
//
//  Created by OlehMalichenko on 08.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import UIKit
import CoreData

class TariffHandler: NSObject {
    
    
    
    // MARK: PUBLIC
    // MARK: - ввод нового тарифа
    class func inputTariff(_ tariffString: String,
                           toService name: String,
                           dateString: String,
                           parameterToTariffString: [String : String]?) -> (result: Bool, notice: Notices?, tariffObj: Tariffs?) {
        // проверка на наличие установленного на эту дату тарифа (если есть - задействуется функция newParametersInExistTariff)
        guard let checkTariff = CoreDataHandler.fetchTariffsForThisDate(dateString, inService: name) else {
            return (false, Notices.errorCoreData, nil)
        }
        guard checkTariff.isEmpty else {
            let tuplResult = newParametersInExistTariff(inService: name, date: dateString, tariffString: tariffString, parToTariffSrting: parameterToTariffString)
            return tuplResult
        }
        // извлечение тарифа из String в Double
        guard let tariffService = tariffString.transferToDouble() else {
            return (false, Notices.impossiblyStringToDouble, nil)
        }
        guard tariffService > 0 else {return (false, Notices.incorrectTariff, nil)}
        // извлечение диференциированного тарифа из String в Double с использованием функции трансформации соотвествующего словаря
        var parameterToTariff: [Double : Double]? = nil
        if parameterToTariffString != nil {
            let parameterToTariffTupl = trunsformDictionaryStringToDouble(parameterToTariffString!)
            guard parameterToTariffTupl.result != nil  else {
                return (false, parameterToTariffTupl.notice, nil)
            }
            parameterToTariff = parameterToTariffTupl.result!
        }
        // сохранение тарифа в CoreData
        guard CoreDataHandler.saveTariff(nameService: name, date: dateString, tariffService: tariffService, parameterToTariff: parameterToTariff) else {
            return (false, Notices.errorCoreData, nil)
        }
        // извлечение сохраненного тарифа для дальнейшего показа
        guard let fetchTariffForThisDate = CoreDataHandler.fetchTariffsForThisDate(dateString, inService: name) else {
            return (true, Notices.impossiblyReadDateFromCD, nil) // тут сохранение уже удалось но при извлечении получилась ошибка
        }
        guard !fetchTariffForThisDate.isEmpty else {
            return (true, Notices.noTariffs, nil) // тут извлечение удалось, но по каким-либо причинам возврат был пустой
        }
        // использование функции для поиска блоков подпадающих под тариф и их (блоков) добавление в тариф
        // если добавление произошло эта функция возвращает nil если нет то Notice
        guard let tariffObject = addingBlocksInNewTariff(fetchTariffForThisDate.first!).0 else {
            return (true, Notices.noUpdateBlocksWhereNewTariff, fetchTariffForThisDate.first!)
        }
        // обновление данных в прикрепленных блоках
        guard let blocksInTariff = tariffObject.blockInTariff as? Set<Block> else {
            return (true, Notices.noBlocksInTariff, fetchTariffForThisDate.first!)
        }
        guard updateValsInSetBlocks(inBlock: blocksInTariff).result else {
            return (true, Notices.noUpdateBlocksWhereNewTariff, fetchTariffForThisDate.first!)
        }
        return (true, nil, fetchTariffForThisDate.first!)
    }
    
    
    
    // MARK: - вывод всей информации содержащийся в тарифе после функции inputTariff
    // (входящий папаметр - кортеж после inputTariff)
    class func outputTariffAfterInput(tupl: (result: Bool, notice: Notices?, tariffObj: Tariffs?)) -> [Properties : String] {
        var result = [Properties : String]()
        switch tupl {
        case (true, nil, _) where tupl.tariffObj != nil:
            result = parsedTariff(tupl.tariffObj!)
        case (_, _, nil) where tupl.notice != nil:
            result[.errorComlete] = tupl.notice!.rawValue
        default: break
        }
        return result
    }
    
    
    
    // MARK: - вывод всей информации содержащейся в тарифе по запросу из View
    class func outputTariff(inService name: String, dateString: String) -> [Properties : String] {
        var result = [Properties : String]()
        guard let tariffArray = CoreDataHandler.fetchTariffsForThisDate(dateString, inService: name) else {
            return [Properties.errorComlete : Notices.errorCoreData.rawValue]
        }
        guard !tariffArray.isEmpty else {return [Properties.errorComlete : Notices.noTariffs.rawValue]}
        let tariffObject = tariffArray.first!
        result = parsedTariff(tariffObject)
        return result
    }
    
    
    
    // MARK: - обновление существующего тарифа.
    //Так как из вью будут приходить стринговые параметры - для начала поиск данного тарифа
    class func newParametersInExistTariff(inService name: String, date: String, tariffString: String, parToTariffSrting: [String : String]?) -> (result: Bool, notice: Notices?, tariffObj: Tariffs?) {
        // получение Double тарифа
        guard let tariff = tariffString.transferToDouble() else {
            return (false, Notices.impossiblyStringToDouble, nil)
        }
        // получение значения дифференциального тарифа
        var parameterToTariff: [Double : Double]? = nil
        if parToTariffSrting != nil {
            let parToTariffTupl = trunsformDictionaryStringToDouble(parToTariffSrting!)
            guard  parToTariffTupl.result != nil else {
                return (false, parToTariffTupl.notice, nil)
            }
            parameterToTariff = parToTariffTupl.result
        }
        // поиск тарифа для обновления (такой должен быть точно, поскольку входящая дата и имя сервиса происходят из вью от сохранения тарифа )
        guard let fetchTariffArray = CoreDataHandler.fetchTariffsForThisDate(date, inService: name) else {
            return (false, Notices.errorCoreData, nil)
        }
        guard !fetchTariffArray.isEmpty else {
            return (false, Notices.noTariffs, nil)
        }
        let tariffObject = fetchTariffArray.first!
        // обновление данных тарифа
        guard CoreDataHandler.updateTariff(tariffObject, tariff: tariff, parameterToTariff: parameterToTariff, newBlockInTariff: nil) else {
            return (false, Notices.errorCoreData, nil)
        }
        // вывод обновленного тарифа
        guard let tariffObjectNewArray = CoreDataHandler.fetchTariffsForThisDate(date, inService: name), !tariffObjectNewArray.isEmpty else {
            return (false, Notices.errorCoreData, nil)
        }
        let tariffObjectNew = tariffObjectNewArray.first!
        
        // обновление данных в прикрепленных блоках
        guard let blocksInTariff = tariffObject.blockInTariff as? Set<Block> else {
            return (true, Notices.noBlocksInTariff, tariffObject)
        }
        guard updateValsInSetBlocks(inBlock: blocksInTariff).result else {
            return (true, Notices.noUpdateBlocksWhereNewTariff, tariffObject)
        }
        return  (true, nil, tariffObjectNew)
    }
    
    
    
    // MARK: - удаление тарифа
    class func deleteTariff(inService name: String, dateString: String) -> (result: Bool, notice: Notices?) {
        guard let fetchTariffForDeleteArray = CoreDataHandler.fetchTariffsForThisDate(dateString, inService: name) else {
            return (false, Notices.errorCoreData)
        }
        guard fetchTariffForDeleteArray.count == 1 else {
            return(false, Notices.noTariffs)
        }
        let tariffForDelete = fetchTariffForDeleteArray.first!
        guard CoreDataHandler.deleteFromCD(object: tariffForDelete) else {
            return (false, Notices.errorCoreData)
        }
        let tuplupdateAllBlocks = updateAllBlocks(inService: name)
        guard tuplupdateAllBlocks.result else {
            return (true, tuplupdateAllBlocks.notice)
        }
        return (true, nil)
    }
    // MARK: -
    
    
    
    // MARK: - PRIVATE
    // MARK: - обновление данных если тариф "вписан" в ранние даты
    /* функция, которая определяет подпадают уже сформированные блоки под введенный тариф или нет
     добавляет эти блоки в BlockInTariff
     обновляет стоимости в этих блоках*/
    private class func addingBlocksInNewTariff(_ tariffObject: Tariffs) -> (Tariffs?, Notices?) {
        // получение всех блоков по определенному сервису
        let name = tariffObject.nameService
        guard let dictionaryDateBlock = BlockHandler.getDictionaryDateBlock(inService: name!) else {
            return (nil, Notices.noBlocks)
        }
        // получение DateInterval для входящего тарифа
        guard let tariffsDI = getTariffsDI(inService: name!) else {
            return (nil, Notices.noBlocks)
        }
        let dateInterval = tariffsDI[tariffObject]!
        // формирование сета блоков подпадающих под действие входящего тарифа
        var setBlocks = Set<Block>()
        for i in dictionaryDateBlock {
            if dateInterval.contains(i.key) &&  (i.value).tariffInBlock != tariffObject {
                setBlocks.insert(i.value) // включение в сет блоков при условии, что они "подпадают" в дату и в них нет этого включенного тарифа
            }
        }
        // прямое сохранение. множество блоков добавляется в тариф
        let context = tariffObject.managedObjectContext!
        tariffObject.addToBlockInTariff(setBlocks as NSSet)
        do {
            try context.save()
            return (tariffObject, nil)
        } catch {
            return (nil, Notices.errorCoreData)
        }
    }
    
    
    
    // MARK: - обновление прикрепленных блоков
    // обновление стоимостей в блоках, когда !!!прикрепленные тарифы обновились
    // так же тут работае функция по подсчету всех неоплаченных сумм updateSumInService
    private class func updateValsInSetBlocks(inBlock block: Set<Block>) -> (result: Bool, notice: Notices?) {
        // вывод тарифа, из которого выведен входящий сет блоков
        guard !block.isEmpty else {
            return (false, Notices.noBlocks)
        }
        let tariffObject = block.first!.tariffInBlock! // тариф должен быть так как сет берется из тарифа
        // операции внутри блока
        if tariffObject.parameterToTariff != nil { // если тариф дифференциальный
            for i in block { // цикл в сете блоков и соотвествующие операции с конкретным блоком
                if i.amount != 0 { // работа с блоком проводится в том случае если есть объём
                    guard let tuplAllotmentVal = BlockHandler.getAllotmentVal(amount: i.amount, tariff: tariffObject) else {
                        return (false, Notices.impossiblyCalculateAmountVal)
                    }
                    let tariffAmountVal = tuplAllotmentVal.tariffAmountVals
                    let allVal = tuplAllotmentVal.allVal
                    let forPay = i.isPay ? allVal - i.valDifference : allVal
                    let isPay = forPay > 0 ? false : true
                    guard CoreDataHandler.updateBlock(i, newMark: nil, newAmount: nil, newOneTariff: tariffObject.tariffService, newVal: allVal, isPay: isPay, newTariffAmountVal: tariffAmountVal, newValDifference: nil, newForPay: forPay, newTariffInBlock: nil) else { return (false, Notices.errorCoreData) }
                }
            }
        } else { // в случае если тариф не дифференциальный - аналогичная работа с блоком
            for i in block {
                if i.amount != 0 {
                    let tariff = i.tariffInBlock!.tariffService
                    let amount = i.amount
                    let allVal = tariff * amount
                    var tariffAmountVal = (i.tariffAmountVal as? [Double : [Double]]) // если до этого в блоке были диверенциированные параметры
                    if tariffAmountVal != nil && !((tariffAmountVal?.isEmpty)!) {
                        tariffAmountVal?.removeAll() // удаление данных о дифференциированных параметрах
                    }
                    let forPay = i.isPay ? allVal - i.valDifference : allVal
                    let isPay = forPay > 0 ? false : true
                    guard CoreDataHandler.updateBlock(i, newMark: nil, newAmount: nil, newOneTariff: tariff, newVal: allVal, isPay: isPay, newTariffAmountVal: tariffAmountVal, newValDifference: nil, newForPay: forPay, newTariffInBlock: nil) else {
                        return (false, Notices.errorCoreData) }
                }
            }
        }
        //обновление данных сервиса по подсчету общих сумм
        let tuplUpdateSum = ServiceHandler.updateSumInService(block.first!.nameService!)
        guard tuplUpdateSum.result else {
            return (true, tuplUpdateSum.notice)
        }
        return (true, nil)
    }
    
    
    
    // MARK: - обновление всего что есть
    private class func updateAllBlocks(inService name: String) -> (result: Bool, notice: Notices?) {
        // вывод всех тарифов в данном сервисе
        guard let allTariffsArray = CoreDataHandler.fetchAllTariffs(inService: name) else {
            return (false, Notices.errorCoreData)
        }
        // два варианта дальнейших действий в зависимости от того остались какие-либо тарифы или нет (в случае их удаления)
        if !allTariffsArray.isEmpty {
        // если тарифы есть - цикл по тарифам - добавление блоков в тарифы - обновление данных блоков
            for i in allTariffsArray {
                let tuplAddingBlockInTariff = addingBlocksInNewTariff(i) // добавление блока в тариф
                guard let tariffObject = tuplAddingBlockInTariff.0 else {
                    return (false, tuplAddingBlockInTariff.1)
                }
                // вывод сета блоков в тарифе и его обновление функцией updateValsInSetBlocks
                if let setBlocks = tariffObject.blockInTariff as? Set<Block> {
                    guard updateValsInSetBlocks(inBlock: setBlocks).result else {
                        return (false, Notices.noUpdateBlocksWhereNewTariff)
                    }
                }
            }
            // обработка варианта если какие-либо блоки не подпадают под действие тарифа
            guard let blocksWithoutTariff = CoreDataHandler.fetchBlocksWithoutTariff(isService: name) else {
                return (false, Notices.errorCoreData)
            } // после выборки блоков, которые не подпадают под какой-либо тариф - цикл по этим блокам
            for i in blocksWithoutTariff {
                let newTariffAmountVal = [Double : [Double]]() // создание пустых показателей
                let newForPay = i.valDifference != 0 ? -(i.valDifference) : 0 // если в буфере есть значение (уже оплачено), то минусовая его часть становиться "для оплаты" для дальнейшего подсчета как переплата
                let isPay = newForPay > 0 ? false : true
                guard CoreDataHandler.updateBlock(i, newMark: nil, newAmount: nil, newOneTariff: 0, newVal: 0, isPay: isPay, newTariffAmountVal: newTariffAmountVal, newValDifference: nil, newForPay: newForPay, newTariffInBlock: nil) else {
                    return (false, Notices.errorCoreData)
                }
            }
        } else { // если тарифов нет вообще - удаление данных о стоимостях и тарифов
            guard let fetchAllBlocks = CoreDataHandler.fetchAllBlocks(inService: name) else {
                return (false, Notices.errorCoreData)
            }
            for i in fetchAllBlocks {
                let newTariffAmountVal = [Double : [Double]]() // создание пустых показателей
                let newForPay = i.valDifference != 0 ? -(i.valDifference) : 0
                let isPay = newForPay > 0 ? false : true
                guard CoreDataHandler.updateBlock(i, newMark: nil, newAmount: nil, newOneTariff: 0, newVal: 0, isPay: isPay, newTariffAmountVal: newTariffAmountVal, newValDifference: nil, newForPay: newForPay, newTariffInBlock: nil) else {
                    return (false, Notices.errorCoreData)
                }
            }
        }
        // обновление общих сумм в Сервисе
        let tuplUpdateSum = ServiceHandler.updateSumInService(name)
        guard tuplUpdateSum.result else {
            return (true, tuplUpdateSum.notice)
        }
        return (true, nil)
    }
    
    
    
    // MARK: - получение словаря тарифов с DateInterval
   private class func getTariffsDI(inService name: String) -> [Tariffs : DateInterval]? {
        //проверка на предмет возможности получения тарифов и их наличия
        guard let tariffsArray = CoreDataHandler.fetchAllTariffs(inService: name) else {
            return nil
        }
        guard !tariffsArray.isEmpty else {
            return nil
        }
        // получения словаря с Date
        var arrayDateTariffs = [Date : Tariffs]()
        for i in tariffsArray {
            guard let dateString = i.dateTariff else {
                return nil
            }
            guard let date = dateString.getDate() else {
                return nil
            }
            arrayDateTariffs[date] = i
        }
        // получение словаря [Tariffs : DateInterval]
        var result = [Tariffs : DateInterval]()
        for _ in 0..<arrayDateTariffs.count {
            let start = arrayDateTariffs.keys.min()
            let tariffObject = arrayDateTariffs[start!]
            arrayDateTariffs.removeValue(forKey: start!)
            let end = arrayDateTariffs.isEmpty ? Date().addingTimeInterval(315360000) : (arrayDateTariffs.keys.min())?.addingTimeInterval(-86400) // конечная дата - минус 1 сутки
            let dateInterval = DateInterval(start: start!, end: end!)
            result[tariffObject!] = dateInterval
        }
        return result
    }
    
    
    
    // MARK: - объект тарифа в строки
    // работа непосредственно с экземпляром CoreData для перевода всех значений в строки
    private class func parsedTariff(_ tariffObj: Tariffs) -> [Properties : String] {
        var result = [Properties : String]()
        result[.name] = tariffObj.nameService!
        result[.date] = tariffObj.dateTariff!
        result[.tariffService] = tariffObj.tariffService.description
        if tariffObj.parameterToTariff != nil {
            let parameterToTariff = tariffObj.parameterToTariff as! [Double : Double]
            result[.parameterToTariff] = doubleTariffDictionaryToString(parameterToTariff)
        }
        return result
    }
    
    
    
    // MARK: - перевод словаря диференциальных тарифов в строку
    private class func doubleTariffDictionaryToString(_ dictDouble: [Double : Double]) -> String {
        var result = ""
        for i in dictDouble {
            let nextParameter = "За объём свыше - \(i.key.description)\n"
            let nextTariff = "\tтариф - \(i.value.description)\n"
            let oneIteration = nextParameter + nextTariff
            result += oneIteration
        }
        return result
    }
    
    
    
    // MARK: - трансформирует словарь срок в словарь Double
    private class func trunsformDictionaryStringToDouble(_ dictString: [String : String]) -> (result: [Double : Double]?, notice: Notices?) {
        var result = [Double : Double]()
        for i in dictString {
            guard let keyDouble = i.key.transferToDouble() else {
                return (nil, Notices.impossiblyStringToDouble)
            }
            guard let valueDouble = i.value.transferToDouble() else {
                return (nil, Notices.impossiblyStringToDouble)
            }
            result[keyDouble] = valueDouble
        }
        return (result, nil)
    }
}
