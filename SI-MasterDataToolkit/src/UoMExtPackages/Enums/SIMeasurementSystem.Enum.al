enum 58000 "SI Measurement System"
{
    Extensible = true;
    Caption = 'Система одиниць вимірювання';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; SI)
    {
        Caption = 'SI';
    }
    value(2; "Metric Non-SI")
    {
        Caption = 'Метрична поза SI';
    }
    value(3; Imperial)
    {
        Caption = 'Імперська';
    }
    value(4; Other)
    {
        Caption = 'Інша';
    }
}