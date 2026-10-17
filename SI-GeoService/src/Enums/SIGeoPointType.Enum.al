enum 63000 "SI Geo Point Type"
{
    Extensible = true;
    Caption = 'Тип географічної точки';

    value(0; Undefined)
    {
        Caption = 'Не визначено';
    }

    value(1; Entrance)
    {
        Caption = 'В''їзд';
    }

    value(2; Exit)
    {
        Caption = 'Виїзд';
    }

    value(3; Loading)
    {
        Caption = 'Завантаження';
    }

    value(4; Unloading)
    {
        Caption = 'Розвантаження';
    }
}