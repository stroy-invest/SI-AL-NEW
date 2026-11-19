enum 65000 "SI IW Vehicle Sync Status"
{
    Extensible = false;
    value(0; Pending) { Caption = 'Очікує'; }
    value(1; Processing) { Caption = 'Обробляється'; }
    value(2; Completed) { Caption = 'Завершено'; }
    value(3; Failed) { Caption = 'Помилка'; }
}
