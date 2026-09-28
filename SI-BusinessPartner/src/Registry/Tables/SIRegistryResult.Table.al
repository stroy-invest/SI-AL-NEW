table 54006 "SI Registry Result"
{
    Caption = 'Результат реєстру';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
        }

        field(2; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
        }

        field(3; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
        }

        field(4; "Registration No."; Text[50])
        {
            Caption = 'Реєстраційний номер';
        }

        field(5; "Tax Registration No."; Text[50])
        {
            Caption = 'Податковий реєстраційний номер';
        }

        field(6; "Legal Name"; Text[500])
        {
            Caption = 'Юридична назва';
        }

        field(7; "Registry Short Name"; Text[250])
        {
            Caption = 'Скорочена назва з реєстру';
        }

        field(8; "Core Name"; Text[250])
        {
            Caption = 'Основна назва';
        }

        field(9; "Legal Form Short"; Text[50])
        {
            Caption = 'Скорочена юридична форма';
        }

        field(10; Address; Text[500])
        {
            Caption = 'Юридична адреса';
        }

        field(11; Director; Text[250])
        {
            Caption = 'Керівник';
        }

        field(12; "Director Genitive"; Text[250])
        {
            Caption = 'Керівник (родовий відмінок)';
        }

        field(13; "KVED No."; Text[30])
        {
            Caption = 'Код основного КВЕД';
        }

        field(14; "KVED Description"; Text[500])
        {
            Caption = 'Основний КВЕД';
        }

        field(15; "Registration Date"; Text[30])
        {
            Caption = 'Дата реєстрації';
        }

        field(16; "Tax Registration Date"; Text[30])
        {
            Caption = 'Дата податкової реєстрації';
        }

        field(17; "Registry Last Update"; Text[30])
        {
            Caption = 'Останнє оновлення реєстру';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}