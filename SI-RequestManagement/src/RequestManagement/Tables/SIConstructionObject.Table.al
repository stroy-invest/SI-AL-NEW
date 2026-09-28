table 52015 "SI Construction Object"
{
    Caption = 'Об''єкти будівництва';
    DataClassification = CustomerContent;
    LookupPageId = "SI Constr. Object List";
    DrillDownPageId = "SI Constr. Object List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Код';
        }

        field(10; Name; Text[100])
        {
            Caption = 'Назва об''єкта';
        }

        field(20; Address; Text[150])
        {
            Caption = 'Адреса об''єкта';
        }

        field(30; City; Text[50])
        {
            Caption = 'Місто';
        }

        field(40; Status; Enum "SI Constr. Object Status")
        {
            Caption = 'Статус об''єкта';
        }

        field(50; Comment; Text[250])
        {
            Caption = 'Коментар';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
