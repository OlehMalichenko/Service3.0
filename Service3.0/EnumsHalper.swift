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
    case valAllotment
    case tariff
    case incomplete
    case noError
    case errorUpdetesBlocks
    case blocksIsUpdates
}

// уведомления для возвращаемых значений
enum Notices: String
{
    case errorCoreData =
    "Ошибка базы данных"
    case blockAlreadyExist =
    "Блок уже существует"
    case impossiblyStringToDouble =
    "Невозможно определить значение параметра"
    case thisFirstMark =
    "Это первый показатель, поэтому определить стоимость услуг невозможно"
    case impossiblyReadDateFromCD =
    "Невозможно прочитать дату из базы данных"
    case inputMarkPreviousPeriod =
    "Введите показания предыдущих периодов"
    case incorrectMark =
    "Введен некорректный показатель"
    case noTariffs =
    "На указанную дату тариф не установлены"
    case needParametersForTariff =
    "Установите параметры для диференциального тарифа"
}
