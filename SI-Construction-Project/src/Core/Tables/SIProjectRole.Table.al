table 60010 "SI Project Role"
{
    Caption = 'Роль будівельного проєкту';
    DataClassification = CustomerContent;
    LookupPageId = "SI Project Roles";
    DrillDownPageId = "SI Project Roles";

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
        }
        field(3; "Assignment Cardinality"; Enum "SI Assignment Cardinality")
        {
            Caption = 'Кратність призначення';
            DataClassification = CustomerContent;
        }
        field(4; "Require Primary"; Boolean)
        {
            Caption = 'Вимагати основного';
            DataClassification = CustomerContent;
        }
        field(5; Active; Boolean)
        {
            Caption = 'Активна';
            DataClassification = CustomerContent;
            InitValue = true;
        }
        field(6; "Assignment Scope"; Enum "SI Assignment Scope")
        {
            Caption = 'Рівень призначення';
            DataClassification = CustomerContent;
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
