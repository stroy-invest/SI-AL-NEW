enum 54070 "SI BP Mat. Run Status"
{
    Extensible = false;
    Caption = 'Стан запуску матеріалізації';

    value(0; Pending)
    {
        Caption = 'Очікує';
    }

    value(1; Running)
    {
        Caption = 'Виконується';
    }

    value(2; Failed)
    {
        Caption = 'Помилка';
    }

    value(3; Completed)
    {
        Caption = 'Завершено';
    }

    value(4; Compensating)
    {
        Caption = 'Виконується компенсація';
    }

    value(5; Compensated)
    {
        Caption = 'Компенсовано';
    }

    value(6; "Manual Intervention")
    {
        Caption = 'Потрібне ручне втручання';
    }
}