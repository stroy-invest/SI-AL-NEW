table 50411 "SI EDS Operation"
{
    Caption = 'Операції EDS';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Code"; Code[50])
        {
            Caption = 'Код сервісу';
            TableRelation = "SI EDS Service".Code;
            NotBlank = true;
        }

        field(2; Code; Code[50])
        {
            Caption = 'Код операції';
            NotBlank = true;
        }

        field(3; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(4; "HTTP Method"; Enum "SI EDS HTTP Method")
        {
            Caption = 'HTTP метод';
        }

        field(5; "Relative Path"; Text[250])
        {
            Caption = 'Відносний шлях';
        }

        field(6; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }

        field(7; "Operation Group Code"; Code[50])
        {
            Caption = 'Група операцій';

            TableRelation =
                "SI EDS Operation Group".Code
                where("Service Code" = field("Service Code"));
        }

        field(8; "Log Response Body"; Boolean)
        {
            Caption = 'Зберігати тіло відповіді в журналі';
            DataClassification = SystemMetadata;
            InitValue = false;
        }

        field(9; "Async Retry Mode"; Enum "SI EDS Async Retry Mode")
        {
            Caption = 'Повтор після HTTP 202';
            DataClassification = SystemMetadata;
            InitValue = None;
        }

        field(10; "Async Max Attempts"; Integer)
        {
            Caption = 'Макс. фонових спроб';
            DataClassification = SystemMetadata;
            InitValue = 10;
            MinValue = 1;
        }
    }

    keys
    {
        key(PK; "Service Code", Code)
        {
            Clustered = true;
        }

        key(ServiceGroup; "Service Code", "Operation Group Code", Code)
        {
        }
    }
}