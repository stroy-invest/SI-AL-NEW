enum 50600 "SI Identity Resolve Status"
{
    Extensible = false;
    Caption = 'Результат визначення ідентичності';

    value(0; "Not Assigned")
    {
        Caption = 'Не призначено';
    }
    value(1; Resolved)
    {
        Caption = 'Визначено';
    }
    value(2; Ambiguous)
    {
        Caption = 'Неоднозначно';
    }
}
