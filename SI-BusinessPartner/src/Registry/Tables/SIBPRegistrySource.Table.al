table 54090 "SI BP Registry Source"
{
    Caption = 'Джерело реєстрових даних BP';
    DataClassification = CustomerContent;
    LookupPageId = "SI BP Registry Sources";
    DrillDownPageId = "SI BP Registry Sources";

    fields
    {
        field(1; "Entity Type"; Enum "SI BP Entity Type")
        {
            Caption = 'Тип контрагента';

            trigger OnValidate()
            begin
                CheckEntityType();
            end;
        }
        field(2; Priority; Integer)
        {
            Caption = 'Пріоритет';
            MinValue = 1;
        }
        field(3; "Source Code"; Code[50])
        {
            Caption = 'Код джерела';
            NotBlank = true;
            TableRelation = "SI EDS Provider".Code;

            trigger OnValidate()
            var
                Provider: Record "SI EDS Provider";
            begin
                if "Source Code" = '' then begin
                    Description := '';
                    exit;
                end;

                Provider.Get("Source Code");
                Description := CopyStr(Provider.Description, 1, MaxStrLen(Description));
            end;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Назва джерела';
        }
        field(5; "EDS Service Code"; Code[50])
        {
            Caption = 'Сервіс EDS';
            TableRelation = "SI EDS Service".Code;

            trigger OnValidate()
            begin
                if "EDS Service Code" <> xRec."EDS Service Code" then
                    Validate("EDS Operation Code", '');
            end;
        }
        field(6; "EDS Operation Code"; Code[50])
        {
            Caption = 'Операція EDS';
            TableRelation = "SI EDS Operation".Code where("Service Code" = field("EDS Service Code"));
        }
        field(7; Enabled; Boolean)
        {
            Caption = 'Увімкнено';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Entity Type", Priority)
        {
            Clustered = true;
        }
        key(BySource; "Entity Type", "Source Code") { }
    }

    trigger OnInsert()
    begin
        ValidateConfiguration();
    end;

    trigger OnModify()
    begin
        ValidateConfiguration();
    end;

    procedure SelectEDSRoute(): Boolean
    var
        Route: Record "SI EDS Provider Route";
        Provider: Record "SI EDS Provider";
        Service: Record "SI EDS Service";
        Operation: Record "SI EDS Operation";
        RouteLookup: Page "SI BP EDS Route Lookup";
    begin
        Route.SetRange(Enabled, true);
        RouteLookup.SetTableView(Route);
        RouteLookup.LookupMode(true);
        if RouteLookup.RunModal() <> Action::LookupOK then
            exit(false);

        RouteLookup.GetRecord(Route);
        Provider.Get(Route."Provider Code");
        Provider.TestField(Enabled, true);
        Service.Get(Route."Service Code");
        Service.TestField(Enabled, true);
        Operation.Get(Route."Service Code", Route."Operation Code");
        Operation.TestField(Enabled, true);

        Validate("Source Code", Route."Provider Code");
        Validate("EDS Service Code", Route."Service Code");
        Validate("EDS Operation Code", Route."Operation Code");
        exit(true);
    end;

    local procedure CheckEntityType()
    begin
        if "Entity Type" = "Entity Type"::" " then
            Error('Вкажіть тип контрагента.');
    end;

    local procedure ValidateConfiguration()
    var
        Existing: Record "SI BP Registry Source";
    begin
        CheckEntityType();
        TestField(Priority);
        TestField("Source Code");
        TestField("EDS Service Code");
        TestField("EDS Operation Code");

        // Avoid duplicate source definitions within the same entity type.
        Existing.SetRange("Entity Type", "Entity Type");
        Existing.SetRange("Source Code", "Source Code");
        Existing.SetFilter(Priority, '<>%1', Priority);
        if not Existing.IsEmpty() then
            Error('Джерело %1 вже налаштовано для цього типу контрагента.', "Source Code");
    end;
}
