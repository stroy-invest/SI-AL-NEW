enum 61017 "SI VSC Status"
{
    Extensible = false;
    Caption = 'Статус каналу постачання';

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
    value(3; Closed)
    {
        Caption = 'Закритий';
    }
}
