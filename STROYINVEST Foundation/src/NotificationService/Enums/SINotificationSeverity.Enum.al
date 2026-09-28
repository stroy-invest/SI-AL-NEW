enum 50200 "SI Notification Severity"
{
    Extensible = true;
    Caption = 'Рівень важливості повідомлення';

    value(0; Information)
    {
        Caption = 'Інформація';
    }

    value(1; Success)
    {
        Caption = 'Успішно';
    }

    value(2; Warning)
    {
        Caption = 'Попередження';
    }

    value(3; Error)
    {
        Caption = 'Помилка';
    }

    value(4; Critical)
    {
        Caption = 'Критично';
    }
}