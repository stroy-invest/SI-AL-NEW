table 54050 "SI BP Bank Account"
{
    Caption = 'Банківські рахунки ролі';
    DataClassification = CustomerContent;
    DataCaptionFields = "Role Code", Code, "Bank Name";

    fields
    {
        field(1; "Role Code"; Code[30])
        {
            Caption = 'Код ролі';
            TableRelation = "SI BP Role".Code;
            NotBlank = true;
        }

        field(2; Code; Code[20])
        {
            Caption = 'Код';
            NotBlank = true;
        }

        field(3; "Business Partner No."; Code[20])
        {
            Caption = 'Контрагент';
            TableRelation = "SI Business Partner"."No.";
            Editable = false;
        }

        field(10; IBAN; Text[50])
        {
            Caption = 'IBAN';
            Editable = false;
        }

        field(11; "Account No."; Text[30])
        {
            Caption = 'Номер банківського рахунку';
            Editable = false;
        }

        field(12; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            TableRelation = "Country/Region".Code;
            Editable = false;
        }

        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Код валюти';
            TableRelation = Currency.Code;
        }

        field(14; "Bank Branch No."; Code[20])
        {
            Caption = 'Номер відділення банку';
            Editable = false;
        }

        field(20; "NBU ID"; Code[20])
        {
            Caption = 'ID НБУ';
            Editable = false;
        }

        field(21; MFO; Code[6])
        {
            Caption = 'МФО';
            Editable = false;
        }

        field(22; "Bank EDRPOU"; Code[8])
        {
            Caption = 'ЄДРПОУ банку';
            Editable = false;
        }

        field(23; "Bank Name"; Text[250])
        {
            Caption = 'Назва банку';
            Editable = false;
        }

        field(24; "Bank Full Name"; Text[250])
        {
            Caption = 'Повна назва банку';
            Editable = false;
        }

        field(25; "Bank Address"; Text[250])
        {
            Caption = 'Адреса банку';
            Editable = false;
        }

        field(26; "Bank City"; Text[100])
        {
            Caption = 'Місто';
            Editable = false;
        }

        field(27; "Bank Postal Code"; Code[20])
        {
            Caption = 'Поштовий індекс';
            Editable = false;
        }

        field(28; "Bank Phone"; Text[100])
        {
            Caption = 'Телефон банку';
            Editable = false;
        }

        field(29; "Bank Website"; Text[250])
        {
            Caption = 'Вебсайт банку';
            ExtendedDatatype = URL;
            Editable = false;
        }

        field(30; "NBU Status Name"; Text[100])
        {
            Caption = 'Стан НБУ';
            Editable = false;
        }

        field(31; "License Status Name"; Text[100])
        {
            Caption = 'Стан ліцензії';
            Editable = false;
        }

        field(40; "Verification Status"; Enum "SI BP Bank Verify Status")
        {
            Caption = 'Статус перевірки';
            Editable = false;
        }

        field(41; "Verification Source"; Code[20])
        {
            Caption = 'Джерело перевірки';
            Editable = false;
        }

        field(42; "Verified At"; DateTime)
        {
            Caption = 'Перевірено';
            Editable = false;
        }

        field(50; Active; Boolean)
        {
            Caption = 'Активний';
            InitValue = true;
        }

        field(51; Primary; Boolean)
        {
            Caption = 'Основний';
        }

        field(60; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }

        field(61; "Created By"; Text[100])
        {
            Caption = 'Створив';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Role Code", Code)
        {
            Clustered = true;
        }

        key(RoleIBAN; "Role Code", IBAN)
        {
        }

        key(RoleCurrencyPrimary; "Role Code", "Currency Code", Primary)
        {
        }

        key(RoleActiveVerified; "Role Code", Active, "Verification Status")
        {
        }
    }

    trigger OnInsert()
    var
        Role: Record "SI BP Role";
    begin
        Role.Get("Role Code");

        "Business Partner No." :=
            Role."Business Partner No.";

        EnsureUniqueIBAN();
        EnsurePrimary();

        if "Created At" = 0DT then
            "Created At" := CurrentDateTime;

        if "Created By" = '' then
            "Created By" :=
                CopyStr(
                    UserId(),
                    1,
                    MaxStrLen("Created By"));
    end;

    trigger OnModify()
    begin
        EnsureUniqueIBAN();
        EnsurePrimary();
    end;

    local procedure EnsureUniqueIBAN()
    var
        OtherAccount: Record "SI BP Bank Account";
    begin
        if ("Role Code" = '') or (IBAN = '') then
            exit;

        OtherAccount.SetRange(
            "Role Code",
            "Role Code");

        OtherAccount.SetRange(
            IBAN,
            IBAN);

        OtherAccount.SetFilter(
            Code,
            '<>%1',
            Code);

        if not OtherAccount.IsEmpty() then
            Error(
                'IBAN %1 вже використовується в іншому банківському рахунку ролі %2.',
                IBAN,
                "Role Code");
    end;

    local procedure EnsurePrimary()
    var
        OtherAccount: Record "SI BP Bank Account";
    begin
        if not Primary then
            exit;

        OtherAccount.SetRange(
            "Role Code",
            "Role Code");

        OtherAccount.SetRange(
            "Currency Code",
            "Currency Code");

        OtherAccount.SetRange(
            Primary,
            true);

        OtherAccount.SetFilter(
            Code,
            '<>%1',
            Code);

        if not OtherAccount.IsEmpty() then
            Error(
                'Для ролі %1 вже визначено основний рахунок у валюті %2.',
                "Role Code",
                "Currency Code");
    end;
}