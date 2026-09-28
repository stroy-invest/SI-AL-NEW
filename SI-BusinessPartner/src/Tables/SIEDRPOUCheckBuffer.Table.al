table 54005 "SI EDRPOU Check Buffer"
{
    Caption = 'Результат перевірки ЄДРПОУ';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Номер запису';
        }

        field(2; "Registration No."; Text[50])
        {
            Caption = 'ЄДРПОУ';
        }

        field(3; "Full Name"; Text[500])
        {
            Caption = 'Повна назва';
        }

        field(4; "Short Name"; Text[250])
        {
            Caption = 'Скорочена назва';
        }

        field(5; Address; Text[500])
        {
            Caption = 'Юридична адреса';
        }

        field(6; Director; Text[250])
        {
            Caption = 'Керівник';
        }

        field(7; "Director Genitive"; Text[250])
        {
            Caption = 'Керівник (родовий відмінок)';
        }

        field(8; "KVED No."; Text[30])
        {
            Caption = 'Код основного КВЕД';
        }

        field(9; "KVED Description"; Text[500])
        {
            Caption = 'Основний КВЕД';
        }

        field(10; "Tax Registration No."; Text[50])
        {
            Caption = 'Реєстраційний номер ПДВ';
        }

        field(11; "Registration Date"; Text[30])
        {
            Caption = 'Дата реєстрації';
        }

        field(12; "Tax Registration Date"; Text[30])
        {
            Caption = 'Дата реєстрації ПДВ';
        }

        field(13; "Last Update"; Text[30])
        {
            Caption = 'Останнє оновлення реєстру';
        }

        field(20; "BP Tax Registration No."; Text[50])
        {
            Caption = 'Наш реєстраційний номер ПДВ';
        }

        field(21; "BP Legal Form Code"; Code[20])
        {
            Caption = 'Код нашої юридичної форми країни';
        }

        field(22; "BP Legal Form Name"; Text[150])
        {
            Caption = 'Наша юридична форма країни';
        }

        field(23; "Registry Legal Form Code"; Code[20])
        {
            Caption = 'Код юридичної форми країни з реєстру';
        }

        field(24; "Registry Legal Form Name"; Text[150])
        {
            Caption = 'Юридична форма країни з реєстру';
        }

        field(25; "VAT Matches"; Boolean)
        {
            Caption = 'Реєстраційний номер ПДВ збігається';
        }

        field(26; "Legal Form Matches"; Boolean)
        {
            Caption = 'Юридична форма країни збігається';
        }

        field(27; "Has Differences"; Boolean)
        {
            Caption = 'Є розбіжності';
        }

        field(28; "Can Apply Corrections"; Boolean)
        {
            Caption = 'Можна застосувати виправлення';
        }

        field(29; "Comparison Result"; Text[250])
        {
            Caption = 'Результат порівняння';
        }

        field(30; "BP Name"; Text[250])
        {
            Caption = 'Наша назва контрагента';
        }

        field(31; "Registry Business Name"; Text[250])
        {
            Caption = 'Назва з реєстру';
        }

        field(32; "Name Needs Fill"; Boolean)
        {
            Caption = 'Потрібно заповнити назву';
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
