table 50193 "SI Country Currency"
{
    Caption = 'Валюти країн';
    DataClassification = CustomerContent;

    LookupPageId = "SI Country Currencies";
    DrillDownPageId = "SI Country Currencies";

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Код країни/регіону';
            TableRelation = "Country/Region".Code;
            NotBlank = true;
        }

        field(2; "Currency Code"; Code[10])
        {
            Caption = 'Код валюти';
            TableRelation = Currency.Code;
            NotBlank = true;
        }

        field(3; Priority; Integer)
        {
            Caption = 'Пріоритет';
            InitValue = 1;
            MinValue = 1;

            trigger OnValidate()
            begin
                CheckPriorityUnique();
            end;
        }

        field(10; "Country/Region Name"; Text[50])
        {
            Caption = 'Назва країни/регіону';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "Country/Region".Name
                where(Code = field("Country/Region Code")));
            Editable = false;
        }

        field(11; "Currency Description"; Text[50])
        {
            Caption = 'Назва валюти';
            FieldClass = FlowField;
            CalcFormula = lookup(
                Currency.Description
                where(Code = field("Currency Code")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Country/Region Code", "Currency Code")
        {
            Clustered = true;
        }

        key(CountryPriority; "Country/Region Code", Priority)
        {
        }
    }

    local procedure CheckPriorityUnique()
    var
        SICountryCurrency: Record "SI Country Currency";
    begin
        SICountryCurrency.SetRange("Country/Region Code", "Country/Region Code");
        SICountryCurrency.SetRange(Priority, Priority);

        if SICountryCurrency.FindFirst() then
            if SICountryCurrency.SystemId <> SystemId then
                Error(
                    'Для країни %1 вже існує запис із пріоритетом %2.',
                    "Country/Region Code",
                    Priority);
    end;
}