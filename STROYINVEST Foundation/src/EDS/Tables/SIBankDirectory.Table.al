table 50440 "SI Bank Directory"
{
    Caption = 'Довідник банків';
    DataClassification = CustomerContent;

    DrillDownPageId = "SI Bank Directory";
    LookupPageId = "SI Bank Directory";

    fields
    {
        field(1; "NBU ID"; Code[20])
        {
            Caption = 'ID НБУ';
            NotBlank = true;
        }

        field(2; MFO; Code[6])
        {
            Caption = 'МФО';
        }

        field(3; EDRPOU; Code[8])
        {
            Caption = 'ЄДРПОУ';
        }

        field(9; Name; Text[250])
        {
            Caption = 'Назва';
        }

        field(10; "Short Name"; Text[250])
        {
            Caption = 'Коротка назва';
        }

        field(11; "Full Name"; Text[250])
        {
            Caption = 'Повна назва';
        }

        field(12; "English Name"; Text[250])
        {
            Caption = 'Назва англійською';
        }

        field(13; "English Short Name"; Text[250])
        {
            Caption = 'Коротка назва англійською';
        }

        field(20; Region; Text[100])
        {
            Caption = 'Область';
        }

        field(21; City; Text[100])
        {
            Caption = 'Населений пункт';
        }

        field(22; Address; Text[250])
        {
            Caption = 'Адреса';
        }

        field(23; "Postal Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
        }

        field(24; Phone; Text[100])
        {
            Caption = 'Телефон';
        }

        field(25; Website; Text[250])
        {
            Caption = 'Вебсайт';
            ExtendedDatatype = URL;
        }

        field(30; "NBU Status Code"; Code[10])
        {
            Caption = 'Код стану НБУ';
        }

        field(31; "NBU Status Name"; Text[100])
        {
            Caption = 'Стан НБУ';
        }

        field(32; "Open Date"; Date)
        {
            Caption = 'Дата відкриття';
        }

        field(33; "Close Date"; Date)
        {
            Caption = 'Дата закриття';
        }

        field(40; "License No."; Integer)
        {
            Caption = 'Номер ліцензії';
        }

        field(41; "License Granted At"; Date)
        {
            Caption = 'Дата надання ліцензії';
        }

        field(42; "License Status"; Integer)
        {
            Caption = 'Статус ліцензії';
        }

        field(43; "License Status Name"; Text[100])
        {
            Caption = 'Стан ліцензії';
        }

        field(44; "License Date"; Date)
        {
            Caption = 'Дата ліцензії';
        }

        field(50; Active; Boolean)
        {
            Caption = 'Активний';
        }

        field(60; "Last Sync At"; DateTime)
        {
            Caption = 'Остання синхронізація';
            Editable = false;
        }

        field(61; "Last Sync Run ID"; Guid)
        {
            Caption = 'ID останньої синхронізації';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "NBU ID")
        {
            Clustered = true;
        }

        key(MFOKey; MFO)
        {
        }

        key(EDRPOUKey; EDRPOU)
        {
        }

        key(NameKey; Name)
        {
        }

        key(ActiveName; Active, Name)
        {
        }
    }
}
