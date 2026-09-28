enum 54071 "SI BP Mat. Step Status"
{
    Extensible = false;
    Caption = 'Стан кроку матеріалізації';

    value(0; Pending)
    {
        Caption = 'Очікує';
    }

    value(1; Running)
    {
        Caption = 'Виконується';
    }

    value(2; Completed)
    {
        Caption = 'Завершено';
    }

    value(3; Failed)
    {
        Caption = 'Помилка';
    }

    value(4; Skipped)
    {
        Caption = 'Пропущено';
    }

    value(5; Compensated)
    {
        Caption = 'Компенсовано';
    }
}