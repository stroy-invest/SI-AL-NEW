enum 59104 "SI WB Basis Type"
{
    Extensible = false;
    Caption = 'Тип підстави';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    value(10; "Purchase Order")
    {
        Caption = 'Purchase Order';
    }

    value(20; "Sales Order")
    {
        Caption = 'Sales Order';
    }

    value(30; Request)
    {
        Caption = 'Заявка';
    }
}
