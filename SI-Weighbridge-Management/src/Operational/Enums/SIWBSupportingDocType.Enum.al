enum 59110 "SI WB Supporting Doc Type"
{
    Extensible = false;
    Caption = 'Тип супровідного документа';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    value(10; TTN)
    {
        Caption = 'ТТН';
    }

    value(20; "Vendor Delivery Note")
    {
        Caption = 'Видаткова постачальника';
    }

    value(30; "Delivery Note")
    {
        Caption = 'Видаткова накладна';
    }

    value(35; "Internal Transfer Document")
    {
        Caption = 'Документ внутрішнього переміщення';
    }

    value(40; "Product Passport")
    {
        Caption = 'Паспорт на продукцію';
    }

    value(90; Other)
    {
        Caption = 'Інший';
    }
}
