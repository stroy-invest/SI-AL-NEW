table 50613 "SI Workforce Capability"
{
    Caption = 'Workforce Capabilities';
    DataClassification = CustomerContent;
    LookupPageId = "SI Workforce Capabilities";
    DrillDownPageId = "SI Workforce Capabilities";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Active; Boolean)
        {
            Caption = 'Active';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
