//
//  ServiceHandler.swift
//  Service3.0
//
//  Created by OlehMalichenko on 08.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import UIKit
import CoreData

class ServiceHandler: NSObject {
    
    // ввод нового сервиса
    class func inputService(name: String) -> (result: Bool, notice: Notices?) {
        // проверка на предмет наличия такого же сервиса
        guard let allServices = CoreDataHandler.fetchServiceForName(name) else {
            return (false, Notices.errorCoreData)
        }
        guard allServices.isEmpty else {
            return (false, Notices.serviceAlreadyExist)
        }
        // сохранение сервиса
        guard CoreDataHandler.saveService(byName: name, sumVal: nil) else {
            return (false, Notices.errorCoreData)
        }
        return (true, nil)
    }
    
    
    
    // вывод всех сервисов
    class func outputAllServices() -> [String : String]? {
        var result = [String : String]()
        guard let allServices = CoreDataHandler.fetchAllServices() else {
            return nil
        }
        for i in allServices {
            let sum = i.sumVal.roundedToTwoNumbers().description
            result[i.nameService!] = sum
        }
        return result
    }
    
    
    
    // обновление суммы сервиса
    class func updateSumInService(_ name: String) -> (result: Bool, notice: Notices?) {
        guard let seriviceObjectArray = CoreDataHandler.fetchServiceForName(name) else {
            return (false, Notices.errorCoreData)
        }
        guard seriviceObjectArray.count == 1 else {
            return (false, Notices.noService)
        }
        let serviceObject = seriviceObjectArray.first!
        // вывод неоплаченных блоков
        guard let blocksIsNotPay = CoreDataHandler.fetchBlocksThatIsNotPay(inService: name) else {
            return (false, Notices.errorCoreData)
        }
        // вывод блоков которые оплачены, но с дифференциальной стоимостью
        guard let blocksWithValDifference = CoreDataHandler.fetchBlocksWithValDifference(inService: name) else {
            return (false, Notices.errorCoreData)
        }
        // циклы по выведенным блокам
        var newSum = Double()
        for i in blocksIsNotPay {
            newSum += i.val
        }
        for i in blocksWithValDifference {
            newSum += i.valDifference
        }
        guard CoreDataHandler.updateService(serviceObject, newSum: newSum) else {
            return (false, Notices.errorCoreData)
        }
        return (true, nil)
    }
    
    
    
    // оплата блока
    class func isPayBlock(inService name: String, date: String) -> (result: Bool, notice: Notices?) {
        guard let blockArray = CoreDataHandler.fetchBlockForThisDate(date, inService: name) else {
            return (false, Notices.errorCoreData)
        }
        guard blockArray.count == 1 else {
            return (false, Notices.noBlocks)
        }
        let block = blockArray.first!
        guard CoreDataHandler.updateBlock(block, newMark: nil, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: true /*меняется только "оплачено" */, newTariffAmountVal: nil, newValDifference: nil, newTariffInBlock: nil) else {
            return (false, Notices.errorCoreData)
        }
        guard updateSumInService(name).result else {
            return (false, Notices.serviceSumIsNotUpdate)
        }
        return (true, nil)
    }
    
    
    
    // оплата диференциального тарифа
    class func isPayValDifference(inService name: String, date: String) -> (result: Bool, notice: Notices?) {
        guard let blockArray = CoreDataHandler.fetchBlockForThisDate(date, inService: name) else {
            return (false, Notices.errorCoreData)
        }
        guard blockArray.count == 1 else {
            return (false, Notices.noBlocks)
        }
        let block = blockArray.first!
        guard CoreDataHandler.updateBlock(block, newMark: nil, newAmount: nil, newOneTariff: nil, newVal: nil, isPay: nil, newTariffAmountVal: nil, newValDifference: 0 /* обнуляется только дифференциальная стоимость */, newTariffInBlock: nil) else {
            return (false, Notices.errorCoreData)
        }
        guard updateSumInService(name).result else {
            return (false, Notices.serviceSumIsNotUpdate)
        }
        return (true, nil)
    }
    
}
