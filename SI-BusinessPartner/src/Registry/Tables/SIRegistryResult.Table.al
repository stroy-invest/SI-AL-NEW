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

        // Registry Result v2: lookup context. The materializer must not infer
        // identity semantics from a provider-specific payload.
        field(18; "Entity Type"; Enum "SI BP Entity Type")
        {
            Caption = 'Тип контрагента';
        }
        field(19; "Identifier Type"; Enum "SI Registry Identifier Type")
        {
            Caption = 'Тип ідентифікатора';
        }
        field(20; "Identifier Value"; Text[50])
        {
            Caption = 'Значення ідентифікатора';
        }

        // Provider-neutral registry facts added in v2.
        field(21; "Registry Status"; Text[100])
        {
            Caption = 'Статус у реєстрі';
        }
        field(22; "Data Actual At"; DateTime)
        {
            Caption = 'Дані актуальні на';
        }
        field(23; "Address Post Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
        }
        field(24; "Address Region"; Text[100])
        {
            Caption = 'Область';
        }
        field(25; "Address District"; Text[100])
        {
            Caption = 'Район';
        }
        field(26; "Address City"; Text[100])
        {
            Caption = 'Населений пункт';
        }
        field(27; "Address Street"; Text[150])
        {
            Caption = 'Вулиця';
        }
        field(28; "Address Building"; Text[50])
        {
            Caption = 'Будинок';
        }
        field(29; "Address Apartment"; Text[50])
        {
            Caption = 'Квартира/офіс';
        }
        field(30; "Manager Role"; Text[100])
        {
            Caption = 'Роль керівника';
        }
        field(31; "Manager Appointed At"; DateTime)
        {
            Caption = 'Дата призначення керівника';
        }
        field(32; "Manager Authority"; Text[500])
        {
            Caption = 'Повноваження керівника';
        }
        field(33; Phone; Text[100])
        {
            Caption = 'Телефон';
        }
        field(34; Email; Text[250])
        {
            Caption = 'Електронна пошта';
        }
        field(35; Website; Text[250])
        {
            Caption = 'Вебсайт';
        }
        field(36; "Legal Form Name"; Text[100])
        {
            Caption = 'Організаційно-правова форма';
        }

        // Presence metadata is intentionally separate from values.
        // False means "provider did not supply this fact" and MUST NOT clear
        // an existing authoritative BP value during partial/fallback sync.
        field(40; "Identity Provided"; Boolean) { Caption = 'Ідентифікаційні дані надано'; }
        field(41; "Names Provided"; Boolean) { Caption = 'Назви надано'; }
        field(42; "Legal Form Provided"; Boolean) { Caption = 'Юридичну форму надано'; }
        field(43; "Status Provided"; Boolean) { Caption = 'Статус надано'; }
        field(44; "Address Provided"; Boolean) { Caption = 'Адресу надано'; }
        field(45; "Manager Provided"; Boolean) { Caption = 'Керівника надано'; }
        field(46; "Main Activity Provided"; Boolean) { Caption = 'Основний КВЕД надано'; }
        field(47; "Contacts Provided"; Boolean) { Caption = 'Контакти надано'; }

        // Synchronization metadata. These fields describe how the normalized
        // result was obtained; they are not provider payload facts.
        field(50; "Sync Outcome"; Enum "SI Registry Sync Outcome")
        {
            Caption = 'Результат синхронізації';
        }
        field(51; "Primary Provider Code"; Code[50])
        {
            Caption = 'Основний провайдер';
        }
        field(52; "Fallback Used"; Boolean)
        {
            Caption = 'Використано резервного провайдера';
        }
        field(53; "Primary Failure Reason"; Text[250])
        {
            Caption = 'Причина переходу на резервного провайдера';
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