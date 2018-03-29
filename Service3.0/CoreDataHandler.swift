//
//  CoreDataHandler.swift
//  Service3.0
//
//  Created by OlehMalichenko on 07.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHandler: NSObject {
    
    // получение контекста
    class func getContext() -> NSManagedObjectContext {
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        return appdelegate.persistentContainer.viewContext
    }
    
    
    
    // MARK: - Save
    // сохранения Service
    class func saveService(byName name: String, sumVal: Double?) -> Bool {
        let context = getContext()
        let service = Services(context: context)
        service.nameService = name
        service.sumVal = sumVal ?? service.sumVal
        do {
            try context.save()
            print("сохранение сервиса удалось")
            return true
        } catch {
            print("сохранение сервиса НЕ удалось")
            return false
        }
    }
    
    
    
    // сохранение Block
    class func saveBlock(nameService: String, dateString: String) -> Bool {
        guard let date = dateString.getDate() else { return false }
        
        let context = getContext()
        let block = Block(context: context)
        block.nameService = nameService
        block.date = dateString
        
        if let fetchLastTariff = fetchLastTariff(inService: nameService, forDateBlock: dateString) {
            if !fetchLastTariff.isEmpty {
                if let dateLastTariff = fetchLastTariff.first?.dateTariff?.getDate() {
                    if date >= dateLastTariff {
                        let tariff = fetchLastTariff.first
                        block.tariffInBlock = tariff
                    }
                }
            }
        }
        do {
            try context.save()
            print("сохранение блока удалось")
            return true
        } catch {
            print("сохранение блока НЕ удалось")
            return false
        }
    }
    
    
    
    // сохранение Tariff
    class func saveTariff(nameService: String,
                          date: String,
                          tariffService: Double,
                          parameterToTariff: [Double : Double]?) -> Bool
    {
        let context = getContext()
        let tariffObject = Tariffs(context: context)
        tariffObject.nameService = nameService
        tariffObject.dateTariff = date
        tariffObject.tariffService = tariffService
        tariffObject.parameterToTariff = parameterToTariff as NSObject?
        do {
            try context.save()
            print("сохранение тарифа удалось")
            return true
        } catch {
            print("сохранение тарифа НЕ удалось")
            return false
        }
    }
    
    
    
    // MARK: - Fetch
    // найти все Services
    class func fetchAllServices() -> [Services]? {
        let context = getContext()
        var result: [Services]
        let request: NSFetchRequest<Services> = Services.fetchRequest()
        do {
            result = try context.fetch(request)
            print("Все сервисы найдены")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти определенный сервис по имени
    class func fetchServiceForName(_ name: String) -> [Services]? {
        let context = getContext()
        var result: [Services]
        let request: NSFetchRequest<Services> = Services.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@", name)
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Все сервисы найдены")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти все Blocks по имени Service
    class func fetchAllBlocks(inService name: String) -> [Block]? {
        let context = getContext()
        var result: [Block]
        let request: NSFetchRequest<Block> = Block.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@", name)
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Все блоки найдены")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
  
    
    
    // найти блок за определенную дату
    class func fetchBlockForThisDate(_ date: String, inService name: String) -> [Block]? {
        let context = getContext()
        var result: [Block]
        let request: NSFetchRequest<Block> = Block.fetchRequest()
        let predicate = NSPredicate(format: "date == %@ && nameService == %@", argumentArray: [date, name])
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Блок найден")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти блоки которые стоимость по которым указана как неоплаченная
    class func fetchBlocksThatIsNotPay(inService name: String) -> [Block]? {
        let context = getContext()
        let result: [Block]
        let request: NSFetchRequest<Block> = Block.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@ && isPay == %@", argumentArray: [name, false])
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Неоплаченныe блоки найдены")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти оплаченные блоки но с имеющейся дифференциальной стоимостью
    class func fetchBlocksWithValDifference(inService name: String) -> [Block]? {
        let context = getContext()
        let request: NSFetchRequest<Block> = Block.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@ && isPay == %@ && valDifference > %@", argumentArray: [name, true, 0.0])
        request.predicate = predicate
        var result: [Block]
        do {
            result = try context.fetch(request)
            print("Блоки с дифференциальной стоимостью найдены")
            return result
        } catch {
            print("Блоки с дифференциальной стоимостью HE найдены")
            return nil
        }
    }
    
    
    
    // найти все тарифы
    class func fetchAllTariffs(inService name: String) -> [Tariffs]? {
        let context = getContext()
        var result: [Tariffs]
        let request: NSFetchRequest<Tariffs> = Tariffs.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@", name)
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Все тарифы найдены")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти тариф за определенную дату
    class func fetchTariffsForThisDate(_ date: String, inService name: String) -> [Tariffs]? {
        let context = getContext()
        var result: [Tariffs]
        let request: NSFetchRequest<Tariffs> = Tariffs.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@ && dateTariff == %@", argumentArray:[name, date])
        request.predicate = predicate
        do {
            result = try context.fetch(request)
            print("Тариф найден")
            return result
        } catch {
            print("Ошибка базы данных")
            return nil
        }
    }
    
    
    
    // найти последний тариф
    class func fetchLastTariff(inService name: String, forDateBlock dateBlockString: String) -> [Tariffs]? {
        guard let dateBlock = dateBlockString.getDate() else {return nil}
        let context = getContext()
        let request: NSFetchRequest<Tariffs> = Tariffs.fetchRequest()
        let predicate = NSPredicate(format: "nameService == %@", name)
        request.predicate = predicate
        let arrayTariffs: [Tariffs]
        do {
            arrayTariffs = try context.fetch(request)
        } catch {
            return nil
        }
        guard !arrayTariffs.isEmpty else { return arrayTariffs }
        var dictTariff = [Date : Tariffs]()
        for i in arrayTariffs {
            guard let date = i.dateTariff?.getDate() else { return nil }
            if date <= dateBlock {
                dictTariff[date] = i
            }
        }
        guard !dictTariff.isEmpty else { return arrayTariffs }
        let maxDate = dictTariff.keys.max()!
        return [dictTariff[maxDate]!]
    }
    
    
    
    // MARK: - Update
    class func updateBlock(_ block: Block,
                           newMark: Double?,
                           newAmount: Double?,
                           newOneTariff: Double?,
                           newVal: Double?,
                           isPay: Bool?,
                           newTariffAmountVal: [Double : [Double]]?,
                           newValDifference: Double?,
                           newTariffInBlock: Tariffs?) -> Bool
    {
        let context = block.managedObjectContext!
        block.mark = newMark ?? block.mark
        block.amount = newAmount ?? block.amount
        block.oneTariff = newOneTariff ?? block.oneTariff
        block.val = newVal ?? block.val
        block.isPay = isPay ?? block.isPay
        block.valDifference = newValDifference ?? block.valDifference
        block.tariffAmountVal = newTariffAmountVal as NSObject? 
        block.tariffInBlock = newTariffInBlock ?? block.tariffInBlock
        do {
            try context.save()
            print("Обновление блока удалось")
            return true
        } catch {
            return false
        }
    }
    
    
    class func updateTariff(_ tariffObject: Tariffs,
                            tariff: Double?,
                            parameterToTariff: [Double : Double]?,
                            newBlockInTariff: Block?) -> Bool
    {
        let context = tariffObject.managedObjectContext!
        tariffObject.tariffService = tariff ?? tariffObject.tariffService
        tariffObject.parameterToTariff = parameterToTariff as NSObject? 
        if newBlockInTariff != nil {tariffObject.addToBlockInTariff(newBlockInTariff!)}
        do {
            try context.save()
            print("Обновление тарифа удалось")
            return true
        } catch {
            return false
        }
    }
    
    class func updateService(_ service: Services, newSum: Double) -> Bool {
        let context = service.managedObjectContext!
        service.sumVal = newSum
        do {
            try context.save()
            print("Обновление сервиса удалось")
            return true
        } catch {
            return false
        }
    }
    
    
    // MARK: - Delete
    class func deleteFromCD(object: NSManagedObject) -> Bool {
        let context = object.managedObjectContext!
        context.delete(object)
        do {
            try context.save()
            print("Удаление удалось")
            return true
        } catch {
            return false
        }
    }
}
