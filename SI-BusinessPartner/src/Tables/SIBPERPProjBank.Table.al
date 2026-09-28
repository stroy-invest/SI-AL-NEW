// Snapshot банківських рахунків на момент створення projection
table 54061 "SI BP ERP Proj. Bank"
{
    Caption = 'Банківські рахунки ERP-проєкції';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Role Code"; Code[30])
        {
            Caption = 'Код ролі';
            TableRelation = "SI BP ERP Projection"."Role Code";
        }

        field(2; Code; Code[20])
        {
            Caption = 'Код';
        }

        field(10; IBAN; Text[50])
        {
            Caption = 'IBAN';
        }

        field(11; "Account No."; Text[30])
        {
            Caption = 'Номер рахунку';
        }

        field(12; "Currency Code"; Code[10])
        {
            Caption = 'Валюта';
        }

        field(13; "Country/Region Code"; Code[10])
        {
            Caption = 'Країна';
        }

        field(20; "Bank Name"; Text[250])
        {
            Caption = 'Назва банку';
        }

        field(21; MFO; Code[6])
        {
            Caption = 'МФО';
        }

        field(22; "Bank EDRPOU"; Code[8])
        {
            Caption = 'ЄДРПОУ банку';
        }

        field(23; "Bank Address"; Text[250])
        {
            Caption = 'Адреса банку';
        }

        field(24; "Bank City"; Text[100])
        {
            Caption = 'Місто';
        }

        field(25; "Bank Postal Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
        }

        field(26; "Bank Phone"; Text[100])
        {
            Caption = 'Телефон';
        }

        field(30; Primary; Boolean)
        {
            Caption = 'Основний';
        }
    }

    keys
    {
        key(PK; "Role Code", Code)
        {
            Clustered = true;
        }
    }
}