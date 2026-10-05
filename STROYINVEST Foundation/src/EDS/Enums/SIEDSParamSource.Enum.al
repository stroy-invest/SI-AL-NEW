enum 50403 "SI EDS Param. Source"
{
    Extensible = true;
    Caption = 'EDS Parameter Source';

    value(0; Fixed)
    {
        Caption = 'Fixed';
    }

    value(1; Runtime)
    {
        Caption = 'Runtime';
    }

    value(2; Credential)
    {
        Caption = 'Credential';
    }
}
