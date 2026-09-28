enum 59100 "SI WB Operation Type"
{
    Extensible = false;
    Caption = 'Тип операції вагової';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    value(10; Receipt)
    {
        Caption = 'Надходження';
    }

    value(20; Shipment)
    {
        Caption = 'Відвантаження';
    }
}