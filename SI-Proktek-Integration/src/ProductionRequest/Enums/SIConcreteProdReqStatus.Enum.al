enum 57011 "SI Concrete Prod Req Status"
{
    Extensible = true;
    Caption = 'Статус виробничої заявки';

    value(0; New)
    {
        Caption = 'Нова';
    }
    value(10; "Recipe Resolved")
    {
        Caption = 'Рецептуру визначено';
    }
    value(20; "Ready for MES")
    {
        Caption = 'Готова до MES';
    }
    value(30; "Sent to MES")
    {
        Caption = 'Передано до MES';
    }
    value(40; Scheduled)
    {
        Caption = 'Заплановано';
    }
    value(50; "In Production")
    {
        Caption = 'У виробництві';
    }
    value(60; Completed)
    {
        Caption = 'Завершено';
    }
    value(70; Error)
    {
        Caption = 'Помилка';
    }
    value(80; Cancelled)
    {
        Caption = 'Скасовано';
    }
}
