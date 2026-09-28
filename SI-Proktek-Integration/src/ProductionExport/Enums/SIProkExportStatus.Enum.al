enum 57080 "SI Prok Export Status"
{
    Extensible = false;
    Caption = 'Статус експорту Proktek';

    value(0; New)
    {
        Caption = 'Новий';
    }
    value(1; Ready)
    {
        Caption = 'Готово';
    }
    value(2; Error)
    {
        Caption = 'Помилка';
    }
}
