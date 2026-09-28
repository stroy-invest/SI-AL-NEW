enum 59102 "SI WB Shipment Scenario"
{
    Extensible = false;
    Caption = 'Сценарій';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    // Existing numeric values are preserved for compatibility.
    value(10; Sales)
    {
        Caption = 'Продаж';
    }

    value(20; "Internal Transfer")
    {
        Caption = 'Внутрішнє переміщення';
    }

    value(30; Supply)
    {
        Caption = 'Постачання';
    }
}
