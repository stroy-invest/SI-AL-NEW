enum 58001 "SI UoM Kind"
{
    Extensible = true;
    Caption = 'Структурний тип одиниці вимірювання';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Base)
    {
        Caption = 'Базова';
    }
    value(2; Scaled)
    {
        Caption = 'Масштабована';
    }
    value(3; Derived)
    {
        Caption = 'Похідна';
    }
    value(4; Packaging)
    {
        Caption = 'Пакувальна';
    }
}
