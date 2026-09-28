table 53010 "SI Product Family Template"
{
    Caption = 'Шаблон сімейства продуктів';
    DataClassification = CustomerContent;
    DrillDownPageId = "SI Product Family Templates";
    LookupPageId = "SI Product Family Templates";

    fields
    {
        field(1; Code; Code[30])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;

            trigger OnValidate()
            begin
                Code := UpperCase(DelChr(Code, '<>', ' '));
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Заблоковано';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Code, Description, Blocked) { }
    }
}
