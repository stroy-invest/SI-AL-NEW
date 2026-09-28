enum 54032 "SI BP Role Chg. Source"
{
    Extensible = true;
    Caption = 'Джерело зміни ролі';

    value(0; Manual)
    {
        Caption = 'Ручна зміна';
    }

    value(1; Approval)
    {
        Caption = 'Погодження';
    }

    value(2; Automatic)
    {
        Caption = 'Автоматичне правило';
    }

    value(3; "External Check")
    {
        Caption = 'Зовнішня перевірка';
    }
}