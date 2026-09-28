enum 53007 "SI ERP Projection Status"
{
    Extensible = false;
    Caption = 'Статус ERP-проєкції';

    value(0; None)
    {
        Caption = 'Не створено';
    }

    value(5; Previewed)
    {
        Caption = 'Попередньо сформовано';
    }

    value(7; Ready)
    {
        Caption = 'Готово до проєкції';
    }

    value(10; Projected)
    {
        Caption = 'Спроєктовано';
    }

    value(20; Failed)
    {
        Caption = 'Помилка';
    }

    value(30; Outdated)
    {
        Caption = 'Неактуально';
    }
}