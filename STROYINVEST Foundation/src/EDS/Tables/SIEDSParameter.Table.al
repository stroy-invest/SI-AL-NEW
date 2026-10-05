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

            trigger OnValidate()
            begin
                case Source of
                    Source::Fixed:
                        begin
                            Clear("Runtime Key");
                            Clear("Credential Code");
                        end;
                    Source::Runtime:
                        Clear("Credential Code");
                    Source::Credential:
                        begin
                            Clear("Runtime Key");
                            Clear(Value);
                        end;
                end;
            end;
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
            InitValue = false;

            trigger OnValidate()
            begin
                if Enabled then
                    ValidateSetup();
            end;
        }

        field(13; "External Name"; Text[100])
        {
            Caption = 'Зовнішнє ім''я';
        }

        field(14; "Credential Code"; Code[50])
        {
            Caption = 'Код облікових даних';
            TableRelation = "SI EDS Credential".Code where("Provider Code" = field("Provider Code"));
        }

        field(15; "Value Prefix"; Text[50])
        {
            Caption = 'Префікс значення';
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
        TestField("Service Code");
        TestField("Operation Code");
        TestField("Provider Code");
        TestField(Code);

        if "External Name" = '' then
            Error(
                'Для увімкненого параметра %1 необхідно вказати зовнішнє ім''я.',
                Code);

        if (Source = Source::Runtime) and ("Runtime Key" = '') then
            Error(
                'Для runtime-параметра %1 необхідно вказати Runtime Key.',
                Code);

        if Source = Source::Credential then begin
            if Location <> Location::Header then
                Error(
                    'Credential-параметр %1 дозволено використовувати лише в HTTP Header.',
                    Code);

            if "Credential Code" = '' then
                Error(
                    'Для credential-параметра %1 необхідно вказати код облікових даних.',
                    Code);
        end;

        if (Location = Location::Path) and (Source <> Source::Runtime) then
            Error(
                'Path-параметр %1 повинен мати джерело Runtime.',
                Code);

        if (Format = Format::"Name Only") and (Location <> Location::Query) then
            Error(
                'Формат Name Only підтримується лише для Query-параметрів.');
    end;
}