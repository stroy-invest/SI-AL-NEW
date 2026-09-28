enum 53003 "SI Product Config. Status"
{
    Extensible = false;
    Caption = 'Статус конфігурації продукту';

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }

    value(10; Validated)
    {
        Caption = 'Перевірено';
    }

    value(20; Approved)
    {
        Caption = 'Затверджено';
    }

    value(30; Projected)
    {
        Caption = 'Створено ERP-проєкцію';
    }

    value(40; Rejected)
    {
        Caption = 'Відхилено';
    }

    value(50; Archived)
    {
        Caption = 'Архівовано';
    }
}