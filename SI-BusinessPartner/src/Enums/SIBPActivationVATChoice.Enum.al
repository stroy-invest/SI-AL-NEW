enum 54082 "SI BP Activation VAT Choice"
{
    Extensible = false;
    Caption = 'Статус ПДВ для активації';

    value(0; "Not Selected")
    {
        Caption = 'Не вибрано';
    }

    value(1; VAT)
    {
        Caption = 'Платник ПДВ';
    }

    value(2; "Non-VAT")
    {
        Caption = 'Неплатник ПДВ';
    }
}
