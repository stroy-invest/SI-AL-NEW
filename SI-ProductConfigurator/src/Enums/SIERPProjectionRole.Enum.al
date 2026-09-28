enum 53002 "SI ERP Projection Role"
{
    Extensible = false;
    Caption = 'Роль в ERP-проєкції';

    value(0; None)
    {
        Caption = 'Не бере участі в ERP-проєкції';
    }

    value(10; "Item Identity")
    {
        Caption = 'Ідентичність товару';
    }

    value(20; "Variant Identity")
    {
        Caption = 'Ідентичність варіанта';
    }

    value(30; Attribute)
    {
        Caption = 'Лише атрибут';
    }

    value(40; Description)
    {
        Caption = 'Лише назва та пошук';
    }
}
