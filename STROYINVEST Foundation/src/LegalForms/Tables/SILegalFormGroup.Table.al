table 50300 "SI Legal Form Group"
{
    Caption = 'Legal Form Group';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Legal Form Groups";
    LookupPageId = "SI Legal Form Groups";

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

        field(4; "Is Independent"; Boolean)
        {
            Caption = 'Чи є незалежним';
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