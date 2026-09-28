table 50412 "SI EDS Provider"
{
    Caption = 'Провайдери EDS';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[50])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(2; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(3; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
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
}