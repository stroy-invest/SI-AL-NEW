table 50413 "SI EDS Endpoint"
{
    Caption = 'Точки підключення EDS';
    DataClassification = CustomerContent;

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

        field(4; "Base URL"; Text[250])
        {
            Caption = 'Базова URL-адреса';
            NotBlank = true;
        }

        field(5; Priority; Integer)
        {
            Caption = 'Пріоритет';
            InitValue = 0;
            MinValue = 0;
        }

        field(6; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Provider Code", Code)
        {
            Clustered = true;
        }

        key(ProviderPriority; "Provider Code", Priority)
        {
        }
    }
}