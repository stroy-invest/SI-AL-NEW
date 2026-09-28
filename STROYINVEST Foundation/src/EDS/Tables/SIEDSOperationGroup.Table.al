table 50340 "SI EDS Operation Group"
{
    Caption = 'Групи операцій EDS';
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
            Caption = 'Код групи';
            NotBlank = true;
        }

        field(3; Description; Text[250])
        {
            Caption = 'Опис';
        }

        field(4; "Path Prefix"; Text[250])
        {
            Caption = 'Префікс шляху';
        }

        field(5; Sequence; Integer)
        {
            Caption = 'Послідовність';
        }

        field(6; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Service Code", Code)
        {
            Clustered = true;
        }

        key(ServiceSequence; "Service Code", Sequence, Code)
        {
        }
    }
}