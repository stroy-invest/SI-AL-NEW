table 50418 "SI EDS Parameter"
{
    Caption = 'Параметри EDS';
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
            TableRelation = "SI EDS Operation".Code where("Service Code" = field("Service Code"));
            NotBlank = true;
        }

        field(3; "Provider Code"; Code[50])
        {
            Caption = 'Код провайдера';
            TableRelation = "SI EDS Provider".Code;
            NotBlank = true;
        }

        field(4; Sequence; Integer)
        {
            Caption = 'Послідовність';
            MinValue = 0;
        }

        field(5; Code; Code[50])
        {
            Caption = 'Код метаданих';
            NotBlank = true;
        }

        field(6; Location; Enum "SI EDS Param. Location")
        {
            Caption = 'Розташування';
        }

        field(7; Source; Enum "SI EDS Param. Source")
        {
            Caption = 'Джерело значення';
        }

        field(8; Format; Enum "SI EDS Param. Format")
        {
            Caption = 'Формат';
        }

        field(9; "Runtime Key"; Code[50])
        {
            Caption = 'Runtime key';
        }

        field(10; Value; Text[250])
        {
            Caption = 'Фіксоване значення';
        }

        field(11; Required; Boolean)
        {
            Caption = 'Обов''язковий';
        }

        field(12; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }

        field(13; "External Name"; Text[100])
        {
            Caption = 'Зовнішнє ім''я';
        }
    }

    keys
    {
        key(PK; "Service Code", "Operation Code", "Provider Code", Code)
        {
            Clustered = true;
        }

        key(OperationProvider; "Service Code", "Operation Code", "Provider Code", Enabled, Sequence)
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateSetup();
    end;

    trigger OnModify()
    begin
        ValidateSetup();
    end;

    procedure GetExternalName(): Text
    begin
        if "External Name" = '' then
            Error(
                'Для параметра EDS %1 / %2 / %3 / %4 не вказано зовнішнє ім''я API-параметра.',
                "Service Code",
                "Operation Code",
                "Provider Code",
                Code);

        exit("External Name");
    end;

    local procedure ValidateSetup()
    begin
        if Enabled and ("External Name" = '') then
            Error('Для увімкненого параметра %1 необхідно вказати зовнішнє ім''я.', Code);

        if (Source = Source::Runtime) and ("Runtime Key" = '') then
            Error('Для runtime-параметра %1 необхідно вказати Runtime Key.', Code);

        if (Source = Source::Fixed) and ("Runtime Key" <> '') then
            "Runtime Key" := '';

        if (Format = Format::"Name Only") and (Location <> Location::Query) then
            Error('Формат Name Only підтримується лише для Query-параметрів.');
    end;
}
