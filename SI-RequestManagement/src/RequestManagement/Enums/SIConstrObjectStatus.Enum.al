enum 52015 "SI Constr. Object Status"
{
    Extensible = true;

    value(0; Planned)
    {
        Caption = 'Планується';
    }

    value(10; Active)
    {
        Caption = 'Активний';
    }

    value(20; Suspended)
    {
        Caption = 'Роботи призупинено';
    }

    value(30; Completed)
    {
        Caption = 'Завершений';
    }
}
