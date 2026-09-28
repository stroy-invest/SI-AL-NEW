enum 54020 "SI BP Entity Type"
{
    Extensible = true;
    Caption = 'Тип контрагента';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(10; "Legal Entity")
    {
        Caption = 'Юридична особа';
    }
    value(20; "Individual Entrepreneur")
    {
        Caption = 'Фізична особа-підприємець';
    }
    value(30; "Individual")
    {
        Caption = 'Фізична особа без статусу підприємця';
    }
}
