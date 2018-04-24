//
//  ViewController.swift
//  Service3.0
//
//  Created by OlehMalichenko on 07.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let dateJanuary = "January, 18"
//        let dateFebruary = "February, 18"
//        let dateMarch = "March, 18"
//        let dateApril = "April, 18"
//        let dateMay = "May, 18"
//
//        let serviceWater = "Water"
//        let serviceGaz = "Gaz"
//
//        ServiceHandler.inputService(name: serviceWater)
//
//        BlockHandler.newReservationBlock(inService: serviceWater, dateString: dateJanuary)
//        let tuplJanuary = BlockHandler.inputMark("10", toService: serviceWater, dateString: dateJanuary)
////
//        BlockHandler.newReservationBlock(inService: serviceWater, dateString: dateFebruary)
//        let tuplFebruary = BlockHandler.inputMark("20", toService: serviceWater, dateString: dateFebruary)
////
//        BlockHandler.newReservationBlock(inService: serviceWater, dateString: dateMarch)
//        let tuplMarch = BlockHandler.inputMark("30", toService: serviceWater, dateString: dateMarch)
//
//        BlockHandler.newReservationBlock(inService: serviceWater, dateString: dateApril)
//        let tuplApril = BlockHandler.inputMark("40", toService: serviceWater, dateString: dateApril)
//
//        BlockHandler.newReservationBlock(inService: serviceWater, dateString: dateMay)
//        let tuplMay = BlockHandler.inputMark("50", toService: serviceWater, dateString: dateMay)




//
//        let parametersJanuary = BlockHandler.outputBlock(forService: "Water", andDate: dateJanuary)
//        let parametersFebruary = BlockHandler.outputBlock(forService: "Water", andDate: dateFebruary)
//        let parametersMarch = BlockHandler.outputBlock(forService: "Water", andDate: dateMarch)
//
//        for i in parametersJanuary {
//            print("\(i.key) - \(i.value)")
//        }
//        for i in parametersFebruary {
//            print("\(i.key) - \(i.value)")
//        }
//        for i in parametersMarch {
//            print("\(i.key) - \(i.value)")
//        }
//
//        TariffHandler.inputTariff("10", toService: serviceWater, dateString: dateJanuary, parameterToTariffString: ["5" : "20"])
//        TariffHandler.inputTariff("10.0", toService: serviceWater, dateString: dateJanuary, parameterToTariffString: nil)
//        TariffHandler.inputTariff("20.0", toService: serviceWater, dateString: dateApril, parameterToTariffString: nil)
//        TariffHandler.newParametersInExistTariff(inService: serviceWater, date: dateJanuary, tariffString: "20.0", parToTariffSrting: ["5" : "200.0"])
//        TariffHandler.newParametersInExistTariff(inService: "Water", date: dateMarch, tariffString: "150", parToTariffSrting: ["3.0" : "1000"])
//        TariffHandler.deleteTariff(inService: serviceWater, dateString: dateJanuary)
        
//        ServiceHandler.isPayBlock(inService: serviceWater, date: dateFebruary)
//        ServiceHandler.isPayBlock(inService: serviceWater, date: dateMarch)
//        ServiceHandler.isPayBlock(inService: serviceWater, date: dateApril)
//        ServiceHandler.isPayBlock(inService: serviceWater, date: dateMay)
//
        
        let tariff = CoreDataHandler.fetchAllTariffs(inService: "Water")
        print(tariff!.count)
        if tariff != nil {
            for i in tariff! {
                print("В тарифе \(i.tariffService.description) присутствует блоков \(i.blockInTariff!.count.description)")
            }
        } else {
            print("Тарифов нет")
        }


        let blocks = CoreDataHandler.fetchAllBlocks(inService: "Water")
        print(blocks!.count)
        if blocks != nil {
            for i in blocks! {
                if i.tariffInBlock != nil {
                    print("В блоке \(i.date!) присутствует тариф \(i.tariffInBlock!.tariffService.description)")
                }
            }
        }
        for i in blocks! {
            print("name - \(i.nameService!)")
            print("date - \(i.date!)")
            print("mark - \(i.mark.description)")
            print("amount - \(i.amount.description)")
            print("tariff - \(String(describing: i.tariffInBlock?.tariffService.description))")
            if i.tariffAmountVal != nil {
            let stringDifferenceTariff = BlockHandler.stringFromDictionary(i.tariffAmountVal as! [Double : [Double]])
            print(stringDifferenceTariff)
            } else {
                print("no difference Parameters")
            }
            print("val - \(i.val.description)")
            if i.valDifference != 0 {
                print("valDifference - \(i.valDifference)")
            }
            print("forPay - \(i.forPay.description)")
            print("isPay = \(i.isPay.description)")
            print("-----------------------------")
        }

        
        let services = ServiceHandler.outputAllServices()
        for i in services! {
            print("услуга \(i.key) - \(i.value)")
        }
        

        
    }
}










