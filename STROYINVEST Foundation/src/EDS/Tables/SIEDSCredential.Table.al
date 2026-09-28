table 50460 "SI EDS Credential"
{
    Caption = 'Облікові дані EDS';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
            TableRelation = "SI EDS Provider".Code;
            NotBlank = true;
        }
        field(2; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Опис';
        }
        field(4; "Credential Type"; Enum "SI EDS Credential Type")
        {
            Caption = 'Тип';
        }
        field(5; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }
        field(10; "Last Changed At"; DateTime)
        {
            Caption = 'Остання зміна';
            Editable = false;
        }
        field(11; "Last Changed By"; Text[100])
        {
            Caption = 'Змінено користувачем';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Provider Code", Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        SecretMgt: Codeunit "SI EDS Secret Mgt.";
    begin
        SecretMgt.DeleteSecret("Provider Code", Code);
    end;

    trigger OnRename()
    begin
        Error('Код облікових даних EDS не можна перейменовувати. Створіть новий запис і видаліть старий.');
    end;
}
