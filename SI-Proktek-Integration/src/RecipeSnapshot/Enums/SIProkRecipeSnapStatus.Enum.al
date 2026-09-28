enum 57014 "SI Prok Recipe Snap Status"
{
    Extensible = false;
    Caption = 'Статус Recipe Snapshot';

    value(0; Draft)
    {
        Caption = 'Чернетка';
    }
    value(1; "Under Testing")
    {
        Caption = 'На випробуванні';
    }
    value(2; Certified)
    {
        Caption = 'Certified';
    }
    value(3; Blocked)
    {
        Caption = 'Заблоковано';
    }
}
