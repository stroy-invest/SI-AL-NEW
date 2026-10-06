enum 54024 "SI Registry Sync Outcome"
{
    Extensible = true;
    Caption = 'Результат синхронізації з реєстром';

    value(0; Undefined) { Caption = 'Не визначено'; }
    value(10; Success) { Caption = 'Успішно'; }
    value(20; "Success With Fallback") { Caption = 'Успішно через резервного провайдера'; }
    value(30; Failed) { Caption = 'Помилка'; }
    value(40; "No Eligible Provider") { Caption = 'Немає доступного провайдера'; }
}
