table 50601 "SI User Identity Purpose"
{
    Caption = 'Функція облікового запису';
    DataClassification = CustomerContent;
    DataPerCompany = true;
    LookupPageId = "SI User Identity Purposes";
    DrillDownPageId = "SI User Identity Purposes";

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Код';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Назва';
            DataClassification = CustomerContent;
        }
        field(3; Active; Boolean)
        {
            Caption = 'Активна';
            DataClassification = CustomerContent;
            InitValue = true;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        Assignment: Record "SI User Identity Assignment";
    begin
        Assignment.SetRange("Purpose Code", Code);
        if Assignment.FindFirst() then
            Error(PurposeInUseErr, Code, Assignment."Entry No.");
    end;

    var
        PurposeInUseErr: Label 'Функцію %1 не можна видалити: вона використовується у призначенні облікового запису №%2. За потреби деактивуйте функцію.', Comment = '%1 = Purpose Code, %2 = Assignment Entry No.';
}
