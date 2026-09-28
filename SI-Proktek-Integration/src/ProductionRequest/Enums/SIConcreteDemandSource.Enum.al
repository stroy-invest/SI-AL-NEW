enum 57012 "SI Concrete Demand Source"
{
    Extensible = true;
    Caption = 'Джерело потреби';

    value(0; Manual)
    {
        Caption = 'Ручна';
    }
    value(10; "External Sale")
    {
        Caption = 'Зовнішній продаж';
    }
    value(20; "Internal Project")
    {
        Caption = 'Внутрішній проєкт';
    }
    value(30; "Supply Request")
    {
        Caption = 'Заявка на забезпечення';
    }
    value(40; Other)
    {
        Caption = 'Інше';
    }
}
