//
//  EnumsHalper.swift
//  Service3.0
//
//  Created by OlehMalichenko on 07.03.2018.
//  Copyright © 2018 OlehMalichenko. All rights reserved.
//

import Foundation

// маркеры для возвращаемых значений
enum Properties
{
    case name
    case mark
    case date
    case amount
    case val
    case forPay
    case oneTariff
    case tariffAmountVal
    case isPay
    case tariffService
    case isAllotment
    case parameterToTariff
    case shortProperties
    case errorComlete
}

// уведомления для возвращаемых значений
enum Notices: String
{
    case errorCoreData =
    "Ошибка базы данных"
    case blockAlreadyExist =
    "Блок уже существует"
    case serviceAlreadyExist =
    "Такой сервис уже существует"
    case noService =
    "Такого сервиса не существует"
    case thisFirstMark =
    "Это первый показатель, поэтому определить стоимость услуг невозможно"
    case impossiblyReadDateFromCD =
    "Невозможно прочитать дату из базы данных"
    case impossiblyStringToDouble =
    "Невозможно определить значение параметра"
    case impossiblyStringToDate =
    "Невозможно определить значение параметра даты"
    case impossiblyCalculateAmountVal =
    "Невозможно расчитать стоимость по диференциальному тарифу"
    case inputMarkPreviousPeriod =
    "Введите показания предыдущих периодов"
    case incorrectMark =
    "Введен некорректный показатель"
    case incorrectTariff =
    "Введен некорректный показатель тарифа"
    case noTariffs =
    "На указанную дату тариф не установлены"
    case noBlocksInTariff =
    "К тарифу не подкреплен ни один показатель"
    case noTariffsInBlock =
    "Период пользования услугой не подпадает под действие ниодного тарифа"
    case noUpdateBlocksWhereNewTariff =
    "При смене тарифа данные предыдущих показателей не обновились"
    case needParametersForTariff =
    "Установите параметры для диференциального тарифа"
    case noBlocks =
    "Нет блоков"
    case noBlockforThisPeriod =
    "Нет блоков за указанный период"
    case isPay =
    "Оплачено"
    case isNotPay =
    "Не оплачено"
    case serviceSumIsNotUpdate =
    "Неоплаченные суммы сервиса не обновились"
}
