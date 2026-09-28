table 50417 "SI EDS Provider Route"
{
    Caption = 'Маршрути провайдерів EDS';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Code"; Code[50])
        {
            Caption = 'Код сервісу';
            TableRelation = "SI EDS Service".Code;
            NotBlank = true;
        }

        field(2; "Operation Code"; Code[50])
        {
            Caption = 'Код операції';

            TableRelation = "SI EDS Operation".Code
                where("Service Code" = field("Service Code"));

            NotBlank = true;
        }

        field(3; Priority; Integer)
        {
            Caption = 'Пріоритет';
            MinValue = 0;
        }

        field(4; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
            TableRelation = "SI EDS Provider".Code;
            NotBlank = true;
        }

        field(5; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Service Code", "Operation Code", Priority, "Provider Code")
        {
            Clustered = true;
        }

        key(Provider; "Provider Code")
        {
        }
    }
}