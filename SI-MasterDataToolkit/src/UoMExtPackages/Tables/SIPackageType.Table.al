table 58000 "SI Package Type"
{
    Caption = 'Типи паковань';
    DataClassification = CustomerContent;
    LookupPageId = "SI Package Types";
    DrillDownPageId = "SI Package Types";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Опис';
        }
        field(3; "Description EN"; Text[100])
        {
            Caption = 'Опис (англ.)';
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}
