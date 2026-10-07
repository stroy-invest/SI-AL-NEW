enum 54080 "SI BP VAT Status"
{
    Extensible = false;
    Caption = 'Статус ПДВ';

    value(0; VAT)
    {
        Caption = 'Платник ПДВ';
    }

    value(1; "Non-VAT")
    {
        Caption = 'Неплатник ПДВ';
    }
}
