enum 54031 "SI BP Role Status"
{
    Extensible = false;
    Caption = 'Стан ролі';

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }

    value(1; Configured)
    {
        Caption = 'Налаштовано';
    }

    value(2; Active)
    {
        Caption = 'Активна';
    }

    value(3; Blocked)
    {
        Caption = 'Заблокована';
    }

    value(4; Inactive)
    {
        Caption = 'Неактивна';
    }

    value(5; Closed)
    {
        Caption = 'Закрита';
    }
}