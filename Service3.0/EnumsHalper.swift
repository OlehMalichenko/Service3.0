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
    case tariffIsEmpty =
    "Тариф не установлен"
    case noTariffForThisDate =
    "Тарифа на указанную дату не существует"
    case firstMark =
    "Это первый показатель, поэтому со стоимостью надо подождать"
    case canNotDetermineStringToDouble =
    "Невозможно определить значение введенных данных"
    case incorrectMark =
    "Введенный показатель меньше предыдущего"
    case marksIsEmpty =
    "Нет никаких показателей"
    case blocksIsEmpty =
    "Никаких записей ещё нет"
    case noMarksForThisDate =
    "Показатель на указанную дату не фиксировался"
    case propertiesIsEmpty =
    "Нет кикаких данных"
    case notPropertiesForThisInterval =
    "За указанный период данных не зафиксировано"
    case impossibleDate =
    "Невозможно определить дату"
    case errorInCoreData =
    "Ошибка базы данных при сохранении"
    case errorCDWherefetchInService =
    "Ошибка базы данных при поиске списка сервисов"
    case noThisService =
    "Тариф устанавливается в сервис которого нет"
    case thisServiceExist =
    "Такой сервис уже существует"
    case tariffDoesNotCover =
    "Тариф не охватывает: "
    case funcWorkedButNotChanges =
    "Всё в норме, но изменений не произошло"
    case updateExistingTariff =
    "Обновлён существующий тариф"
    case errorUpdetesBlocks =
    "Сбой обновления показателей"
    case blocksIsUpdates =
    "Все показатели касающиеся новых тарифов обновлены"
    case canNotGetDateFromString =
    " Невозможно определить дату"
}
