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
    class func saveBlock(nameService: String,
                         date: String,
                         mark: Double,
                         amount: Double?,
                         val: Double?,
                         tariffs: [Double]?,
                         valAllotment: [Double : Double]?) -> Bool
    {
        let context = getContext()
        let block = Block(context: context)
        block.nameService = nameService
        block.date = date
        block.mark = mark
        block.amount = amount ?? block.amount
        block.val = val ?? block.val
        block.tariff = tariffs as NSObject?
        block.valAllotment = valAllotment as NSObject?
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
                          allotmentParameter: Double?,
                          tariffAfter: Double?) -> Bool
    {
        let context = getContext()
        let tariffObject = Tariffs(context: context)
        tariffObject.nameService = nameService
        tariffObject.dateTariff = date
        tariffObject.tariffService = tariffService
        tariffObject.isAllotment = isAllotment ?? tariffObject.isAllotment
        tariffObject.allotmentParameter = allotmentParameter ?? tariffObject.allotmentParameter
        tariffObject.tariffAfter = tariffAfter ?? tariffObject.tariffAfter
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
        let predicate = NSPredicate(format: "nameService == %@ && dateTariff == %@", [name, date])
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
    
    
    // MARK: - Update
    class func updateBlock(_ block: Block,
                           newMark: Double?,
                           newAmount: Double?,
                           newTariff: [Double]?,
                           newVal: Double?,
                           isPay: Bool?,
                           newValAllotment: [Double:Double]?,
                           newValDifference: Double?) -> Bool
    {
        let context = block.managedObjectContext!
        block.mark = newMark ?? block.mark
        block.amount = newAmount ?? block.amount
        block.tariff = newTariff as NSObject? ?? block.tariff
        block.val = newVal ?? block.val
        block.isPay = isPay ?? block.isPay
        block.valAllotment = newValAllotment as NSObject? ?? block.valAllotment
        block.valDifference = newValDifference ?? block.valDifference
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
                            allotmentParameter: Double?,
                            tariffAfter: Double?) -> Bool
    {
        let context = tariffObject.managedObjectContext!
        tariffObject.tariffService = tariff ?? tariffObject.tariffService
        tariffObject.isAllotment = isAllotment ?? tariffObject.isAllotment
        tariffObject.allotmentParameter = allotmentParameter ?? tariffObject.allotmentParameter
        tariffObject.tariffAfter = tariffAfter ?? tariffObject.tariffAfter
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
