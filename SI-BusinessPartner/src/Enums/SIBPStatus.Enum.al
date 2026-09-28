enum 54000 "SI BP Status"
{
    Extensible = true;
    Caption = 'Business Partner Status';

    value(0; Draft)
    {
        Caption = 'Draft';
    }

    value(1; Active)
    {
        Caption = 'Active';
    }

    value(2; Blocked)
    {
        Caption = 'Blocked';
    }

    value(3; Archived)
    {
        Caption = 'Archived';
    }
}