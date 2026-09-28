enum 54000 "SI BP Status"
{
    Extensible = true;
    Caption = 'Статус контрагента';

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }

    value(1; Active)
    {
        Caption = 'Активний';
    }

    value(2; Blocked)
    {
        Caption = 'Заблокований';
    }

    value(3; Archived)
    {
        Caption = 'Архівний';
    }
}