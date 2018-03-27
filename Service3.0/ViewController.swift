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
        
        let dateJanuary = "January, 18"
        let dateFebruary = "February, 18"
        let dateMarch = "March, 18"
        
//        BlockHandler.newReservationBlock(inService: "Water", dateString: dateJanuary)
//        BlockHandler.newReservationBlock(inService: "Water", dateString: dateFebruary)
//        BlockHandler.newReservationBlock(inService: "Water", dateString: dateMarch)
//
//        let tuplJanuary = BlockHandler.inputMark("33", toService: "Water", dateString: dateJanuary)
//        let tuplFebruary = BlockHandler.inputMark("55.6", toService: "Water", dateString: dateFebruary)
//        let tuplMarch = BlockHandler.inputMark("88.8", toService: "Water", dateString: dateMarch)
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
//        TariffHandler.inputTariff("77.0", toService: "Water", dateString: dateFebruary, isAllotment: true, parameterToTariffString: ["3.3" : "777.0"])
//        TariffHandler.inputTariff("10.0", toService: "Water", dateString: dateFebruary, isAllotment: nil, parameterToTariffString: nil)
//        TariffHandler.newParametersInExistTariff(inService: "Water", date: dateJanuary, tariffString: "88.0", parToTariffSrting: ["5.5" : "888.0"])
//        TariffHandler.newParametersInExistTariff(inService: "Water", date: dateFebruary, tariffString: "150", parToTariffSrting: ["3.0" : "1000"])
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
            print("-----------------------------")
        }

    }
    
}










