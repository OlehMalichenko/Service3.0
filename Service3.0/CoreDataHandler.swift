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
    private class func getContext() -> NSManagedObjectContext {
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
            print("сохранение удалось")
            return true
        } catch {
            print("сохранение НЕ удалось")
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
        
        guard let fetchLastTariff = fetchLastTariff(inService: nameService) else {return false}

        if !fetchLastTariff.isEmpty {
            if let dateLastTariff = fetchLastTariff.first?.dateTariff?.getDate() {
                if date >= dateLastTariff {
                    let tariff = fetchLastTariff.first
                    tariff?.addToBlockInTariff(block)
                }
            }
        }
        do {
            try context.save()
            print("сохранение удалось")
            return true
        } catch {
            print("сохранение НЕ удалось")
            return false
        }
    }
    
    // сохранение Tariff
    class func saveTariff(nameService: String,
                          date: String,
                          tariffService: Double,
                          isAllotment: Bool?,
                          parameterToTariff: [Double : Double]?) -> Bool
    {
        let context = getContext()
        let tariffObject = Tariffs(context: context)
        tariffObject.nameService = nameService
        tariffObject.dateTariff = date
        tariffObject.tariffService = tariffService
        tariffObject.isAllotment = isAllotment ?? tariffObject.isAllotment
        tariffObject.parameterToTariff = parameterToTariff as NSObject? ?? tariffObject.parameterToTariff
        do {
            try context.save()
            print("сохранение удалось")
            return true
        } catch {
            print("сохранение НЕ удалось")
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
    
    class func fetchLastTariff(inService name: String) -> [Tariffs]? {
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
        guard arrayTariffs.count > 1 else { return arrayTariffs }
        var dictTariff = [Date : Tariffs]()
        for i in arrayTariffs {
            guard let date = i.dateTariff?.getDate() else { return nil }
            dictTariff[date] = i
        }
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
        block.tariffAmountVal = newTariffAmountVal as NSObject? ?? block.tariffAmountVal
        block.tariffInBlock = newTariffInBlock ?? block.tariffInBlock
        do {
            try context.save()
            print("Обновление удалось")
            return true
        } catch {
            return false
        }
    }
    
    
    class func updateTariff(_ tariffObject: Tariffs,
                            tariff: Double?,
                            isAllotment: Bool?,
                            parameterToTariff: [Double : Double]?,
                            newBlockInTariff: Block?) -> Bool
    {
        let context = tariffObject.managedObjectContext!
        tariffObject.tariffService = tariff ?? tariffObject.tariffService
        tariffObject.isAllotment = isAllotment ?? tariffObject.isAllotment
        tariffObject.parameterToTariff = parameterToTariff as NSObject? ?? tariffObject.parameterToTariff
        if newBlockInTariff != nil {tariffObject.addToBlockInTariff(newBlockInTariff!)}
        do {
            try context.save()
            print("Обновление удалось")
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
            print("Обновление удалось")
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
