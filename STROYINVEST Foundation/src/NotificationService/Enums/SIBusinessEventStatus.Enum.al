enum 50201 "SI Business Event Status"
{
    Extensible = false;
    Caption = 'Статус бізнес-події';

    value(0; New)
    {
        Caption = 'Нова';
    }

    value(1; Processing)
    {
        Caption = 'Обробляється';
    }

    value(2; Completed)
    {
        Caption = 'Завершено';
    }

    value(3; PartiallyCompleted)
    {
        Caption = 'Частково завершено';
    }

    value(4; Failed)
    {
        Caption = 'Помилка';
    }

    value(5; Skipped)
    {
        Caption = 'Пропущено';
    }
}