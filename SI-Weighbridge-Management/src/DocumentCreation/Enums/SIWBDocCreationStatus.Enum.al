enum 59010 "SI WB Doc Creation Status"
{
    Extensible = false;
    Caption = 'Статус автоматичного створення документа';

    value(0; Pending)
    {
        Caption = 'Очікує';
    }

    value(1; Processing)
    {
        Caption = 'Обробляється';
    }

    value(2; Completed)
    {
        Caption = 'Завершено';
    }

    value(3; Error)
    {
        Caption = 'Помилка';
    }
}
