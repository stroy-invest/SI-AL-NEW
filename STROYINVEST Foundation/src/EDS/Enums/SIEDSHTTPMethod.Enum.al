enum 50400 "SI EDS HTTP Method"
{
    Extensible = true;
    Caption = 'EDS HTTP Method';

    value(0; GET)
    {
        Caption = 'GET';
    }

    value(1; POST)
    {
        Caption = 'POST';
    }

    value(2; PUT)
    {
        Caption = 'PUT';
    }

    value(3; PATCH)
    {
        Caption = 'PATCH';
    }

    value(4; DELETE)
    {
        Caption = 'DELETE';
    }
}