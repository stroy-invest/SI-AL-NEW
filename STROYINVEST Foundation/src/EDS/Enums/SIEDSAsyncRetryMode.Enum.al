enum 50469 "SI EDS Async Retry Mode"
{
    Extensible = false;
    Caption = 'EDS Async Retry Mode';

    value(0; None)
    {
        Caption = 'Не повторювати';
    }

    value(1; "Repeat Same Operation")
    {
        Caption = 'Повторювати ту саму операцію';
    }
}
