enum 50420 "SI EDS Inbound Status"
{
    Extensible = true;

    value(0; Accepted)
    {
        Caption = 'Accepted';
    }

    value(10; Processing)
    {
        Caption = 'Processing';
    }

    value(20; Processed)
    {
        Caption = 'Processed';
    }

    value(30; Error)
    {
        Caption = 'Error';
    }
}