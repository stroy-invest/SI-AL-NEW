table 61012 "SI Supply Allocation"
{
    Caption = 'Розподіл забезпечення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Decision No."; Code[20])
        {
            Caption = '№ рішення';
            TableRelation = "SI Supply Decision Header"."No.";
        }
        field(2; "Decision Line No."; Integer)
        {
            Caption = '№ рядка рішення';
            TableRelation = "SI Supply Decision Line"."Line No." where("Decision No." = field("Decision No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = '№ розподілу';
        }
        field(10; "Supply Method"; Enum "SI Supply Method")
        {
            Caption = 'Спосіб забезпечення';

            trigger OnValidate()
            begin
                TestEditable();
                if "Supply Method" = "Supply Method"::Purchase then
                    Clear("Source Location Code");

                if "Supply Method" <> xRec."Supply Method" then begin
                    case "Supply Method" of
                        "Supply Method"::Purchase:
                            ApplyPurchaseDefaults();
                        "Supply Method"::Production:
                            ApplyProductionDefaults();
                        "Supply Method"::Transfer,
                        "Supply Method"::Stock:
                            ApplyProjectTargetLocation();
                    end;

                    ClearRecipeResolution();
                    InvalidateMaterialRequirements();
                    RefreshAllocationReadiness();
                end;
            end;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Кількість';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                TestEditable();
                if Quantity <= 0 then
                    Error('Кількість має бути більшою за нуль.');
                CheckTotalQuantity();
                if Quantity <> xRec.Quantity then
                    InvalidateMaterialRequirements();
            end;
        }
        field(30; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Од. вим.';
            Editable = false;
        }
        field(40; "Required on Site At"; DateTime)
        {
            Caption = 'Потрібно на об''єкті';
            Editable = false;
        }
        field(50; "Source Location Code"; Code[10])
        {
            Caption = 'Склад-джерело';
            TableRelation = Location.Code;

            trigger OnValidate()
            begin
                TestEditable();
                ValidateSourceLocation();
            end;
        }
        field(60; "Target Location Code"; Code[10])
        {
            Caption = 'Склад призначення';
            TableRelation = Location.Code;

            trigger OnValidate()
            var
                ReceivingLocationMgt: Codeunit "SI Purchase Receiving Loc.";
            begin
                TestEditable();
                if ("Supply Method" = "Supply Method"::Purchase) and ("Target Location Code" <> '') then
                    ReceivingLocationMgt.ValidateReceivingLocation("Target Location Code");
            end;
        }
        field(65; "Construction Site Code"; Code[20])
        {
            Caption = 'Буд. майданчик';
            Editable = false;
        }
        field(70; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";
            Editable = false;
        }
        field(80; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(90; Description; Text[250])
        {
            Caption = 'Опис потреби';
            Editable = false;
        }
        field(100; Status; Enum "SI Supply Alloc Status")
        {
            Caption = 'Статус';
            Editable = false;
        }
        field(110; "Execution Reference"; Code[50])
        {
            Caption = 'Документ / посилання виконання';
            Editable = false;
        }
        field(125; "Counts as Allocated"; Boolean)
        {
            Caption = 'Враховувати як розподілене';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(120; "Execution System ID"; Guid)
        {
            Caption = 'SystemId документа виконання';
            Editable = false;
        }
        field(130; "Created By"; Code[50])
        {
            Caption = 'Створено користувачем';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(140; "Created At"; DateTime)
        {
            Caption = 'Створено';
            Editable = false;
        }
        field(200; "Recipe Resolution Status"; Enum "SI Supply Recipe Status")
        {
            Caption = 'Статус визначення рецептури';
            Editable = false;
        }
        field(210; "Selected Recipe No."; Code[50])
        {
            Caption = 'Вибрана рецептура';
            Editable = false;
        }
        field(220; "Selected Revision No."; Integer)
        {
            Caption = 'Вибрана ревізія';
            Editable = false;
        }
        field(230; "Recipe Selection Mode"; Enum "SI Recipe Selection Mode")
        {
            Caption = 'Режим вибору рецептури';
            Editable = false;
        }
        field(240; "Recipe Selected By"; Code[50])
        {
            Caption = 'Рецептуру вибрав';
            TableRelation = User."User Name";
            Editable = false;
        }
        field(250; "Recipe Selected At"; DateTime)
        {
            Caption = 'Рецептуру вибрано';
            Editable = false;
        }
        field(260; "Recipe Selection Reason"; Text[250])
        {
            Caption = 'Причина вибору рецептури';
            Editable = false;
        }
        field(270; "Recipe Candidate Count"; Integer)
        {
            Caption = 'Кількість кандидатів';
            Editable = false;
        }
        field(280; "Recipe Last Validated At"; DateTime)
        {
            Caption = 'Рецептуру перевірено';
            Editable = false;
        }
        field(290; "Recipe Resolution Message"; Text[500])
        {
            Caption = 'Повідомлення визначення рецептури';
            Editable = false;
        }
        field(300; "Material Req. Status"; Enum "SI Material Req Status")
        {
            Caption = 'Статус потреби в матеріалах';
            Editable = false;
        }
        field(310; "Material Req. Checked At"; DateTime)
        {
            Caption = 'Матеріали перевірено';
            Editable = false;
        }
        field(320; "Material Warehouse Code"; Code[10])
        {
            Caption = 'Склад матеріалів';
            TableRelation = Location.Code;
            Editable = false;
        }
        field(330; "Material Req. Message"; Text[500])
        {
            Caption = 'Повідомлення потреби в матеріалах';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Decision No.", "Decision Line No.", "Line No.") { Clustered = true; }
        key(Method; "Supply Method", Status) { }
        key(Execution; "Execution System ID") { }
    }

    trigger OnInsert()
    begin
        TestEditable();
        CopyFromDecisionLine();
        if "Supply Method" = "Supply Method"::Purchase then
            ApplyPurchaseDefaults();
        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
        if "Created At" = 0DT then
            "Created At" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        if SkipExecutionLock then
            exit;

        TestEditable();
        if not IsNullGuid("Execution System ID") then
            Error('Розподіл не можна змінювати після створення документа виконання.');
    end;

    trigger OnDelete()
    begin
        TestEditable();
        if not IsNullGuid("Execution System ID") then
            Error('Розподіл не можна видаляти після створення документа виконання.');
    end;

    procedure MarkExecution(ExecutionReference: Code[50]; ExecutionSystemId: Guid)
    begin
        if IsNullGuid(ExecutionSystemId) then
            Error('Документ виконання не повернув SystemId.');

        SkipExecutionLock := true;
        "Execution Reference" := ExecutionReference;
        "Execution System ID" := ExecutionSystemId;
        Status := Status::Released;
        Modify(true);
        SkipExecutionLock := false;
    end;

    local procedure CopyFromDecisionLine()
    var
        DecisionLine: Record "SI Supply Decision Line";
    begin
        if not DecisionLine.Get("Decision No.", "Decision Line No.") then
            exit;

        "Item No." := DecisionLine."Item No.";
        "Variant Code" := DecisionLine."Variant Code";
        Description := DecisionLine.Description;
        "Unit of Measure Code" := DecisionLine."Unit of Measure Code";
        "Required on Site At" := DecisionLine."Required on Site At";
        "Construction Site Code" := DecisionLine."Construction Site Code";
        if "Supply Method" <> "Supply Method"::Purchase then
            "Target Location Code" := DecisionLine."Target Location Code";

        if Quantity = 0 then
            Quantity := DecisionLine.GetRemainingQuantity();

        if "Supply Method" = "Supply Method"::Production then
            SetDefaultProductionLocation();
    end;


    procedure ApplyPurchaseDefaults()
    var
        ReceivingLocationMgt: Codeunit "SI Purchase Receiving Loc.";
        DefaultLocationCode: Code[10];
    begin
        if "Supply Method" <> "Supply Method"::Purchase then
            exit;

        Clear("Source Location Code");
        Clear("Target Location Code");
        DefaultLocationCode := ReceivingLocationMgt.ResolveDefault("Item No.", "Variant Code");
        if DefaultLocationCode <> '' then
            Validate("Target Location Code", DefaultLocationCode);
    end;

    local procedure ApplyProjectTargetLocation()
    var
        DecisionLine: Record "SI Supply Decision Line";
    begin
        if not DecisionLine.Get("Decision No.", "Decision Line No.") then
            exit;
        "Target Location Code" := DecisionLine."Target Location Code";
    end;

    procedure GetTargetLocationName(): Text[100]
    var
        Location: Record Location;
    begin
        if "Target Location Code" = '' then
            exit('');
        if not Location.Get("Target Location Code") then
            exit("Target Location Code");
        exit(Location.Name);
    end;


    procedure ApplyProductionDefaults()
    begin
        if "Supply Method" <> "Supply Method"::Production then
            exit;

        // Re-apply context defaults also for an already-created empty allocation row.
        CopyFromDecisionLine();
        if "Source Location Code" = '' then
            SetDefaultProductionLocation();
    end;

    local procedure SetDefaultProductionLocation()
    var
        Location: Record Location;
    begin
        if "Source Location Code" <> '' then
            exit;

        SetSourceLocationFilter(Location);
        if not Location.FindFirst() then
            exit;

        // Auto-fill only when the production source is unambiguous.
        if Location.Next() <> 0 then
            exit;

        Validate("Source Location Code", Location.Code);
    end;

    local procedure CheckTotalQuantity()
    var
        DecisionLine: Record "SI Supply Decision Line";
        Allocation: Record "SI Supply Allocation";
        TotalQty: Decimal;
    begin
        if ("Decision No." = '') or ("Decision Line No." = 0) then
            exit;
        if not DecisionLine.Get("Decision No.", "Decision Line No.") then
            exit;

        Allocation.SetRange("Decision No.", "Decision No.");
        Allocation.SetRange("Decision Line No.", "Decision Line No.");
        Allocation.SetFilter("Line No.", '<>%1', "Line No.");
        Allocation.CalcSums(Quantity);
        TotalQty := Allocation.Quantity + Quantity;

        if TotalQty > DecisionLine."Demand Quantity" then
            Error(
                'Розподілена кількість %1 перевищує кількість до забезпечення %2.',
                TotalQty,
                DecisionLine."Demand Quantity");
    end;

    procedure GetConstructionSiteName(): Text[100]
    var
        DecisionLine: Record "SI Supply Decision Line";
    begin
        if "Construction Site Code" = '' then
            exit('');
        if not DecisionLine.Get("Decision No.", "Decision Line No.") then
            exit("Construction Site Code");
        exit(DecisionLine.GetConstructionSiteName());
    end;

    procedure GetSourceLocationName(): Text[100]
    var
        Location: Record Location;
    begin
        if "Source Location Code" = '' then
            exit('');
        if not Location.Get("Source Location Code") then
            exit("Source Location Code");
        exit(Location.Name);
    end;

    procedure RefreshAllocationReadiness()
    begin
        case "Supply Method" of
            "Supply Method"::Production:
                "Counts as Allocated" :=
                    ("Recipe Resolution Status" = "Recipe Resolution Status"::Resolved) and
                    ("Selected Recipe No." <> '') and
                    ("Selected Revision No." <> 0);
            "Supply Method"::Purchase,
            "Supply Method"::Transfer,
            "Supply Method"::Stock:
                "Counts as Allocated" := true;
            else
                "Counts as Allocated" := false;
        end;
    end;

    procedure InvalidateMaterialRequirements()
    var
        MaterialReq: Record "SI Supply Material Req.";
    begin
        if ("Decision No." <> '') and ("Decision Line No." <> 0) and ("Line No." <> 0) then begin
            MaterialReq.SetRange("Decision No.", "Decision No.");
            MaterialReq.SetRange("Decision Line No.", "Decision Line No.");
            MaterialReq.SetRange("Allocation Line No.", "Line No.");
            MaterialReq.DeleteAll();
        end;

        Clear("Material Req. Status");
        Clear("Material Req. Checked At");
        Clear("Material Warehouse Code");
        Clear("Material Req. Message");
    end;

    procedure SetSourceLocationFilter(var Location: Record Location)
    var
        LocationSetup: Record "SI Location Setup";
    begin
        case "Supply Method" of
            "Supply Method"::Production:
                begin
                    GetLocationSetup(LocationSetup);
                    LocationSetup.TestField("Finished Goods Type");
                    Location.SetRange("SI Location Type Code", LocationSetup."Finished Goods Type");
                end;
            "Supply Method"::Purchase:
                Location.SetRange(Code, '');
        end;
    end;

    local procedure ValidateSourceLocation()
    var
        Location: Record Location;
        LocationSetup: Record "SI Location Setup";
    begin
        if "Source Location Code" = '' then
            exit;

        if "Supply Method" = "Supply Method"::Purchase then
            Error('Для способу забезпечення Закупівля склад-джерело не використовується.');

        if "Supply Method" <> "Supply Method"::Production then
            exit;

        GetLocationSetup(LocationSetup);
        LocationSetup.TestField("Finished Goods Type");
        Location.Get("Source Location Code");
        if Location."SI Location Type Code" <> LocationSetup."Finished Goods Type" then
            Error(
                'Для способу забезпечення Виробництво можна вибрати лише склад типу %1.',
                LocationSetup."Finished Goods Type");
    end;

    local procedure GetLocationSetup(var LocationSetup: Record "SI Location Setup")
    begin
        if not LocationSetup.Get('') then
            Error('Не налаштовано Налаштування типів складів у STROYINVEST Foundation.');
    end;

    local procedure TestEditable()
    var
        Header: Record "SI Supply Decision Header";
    begin
        if Header.Get("Decision No.") then
            Header.TestEditable();
    end;

    local procedure ClearRecipeResolution()
    begin
        Clear("Recipe Resolution Status");
        Clear("Selected Recipe No.");
        Clear("Selected Revision No.");
        Clear("Recipe Selection Mode");
        Clear("Recipe Selected By");
        Clear("Recipe Selected At");
        Clear("Recipe Selection Reason");
        Clear("Recipe Candidate Count");
        Clear("Recipe Last Validated At");
        Clear("Recipe Resolution Message");
    end;

    var
        SkipExecutionLock: Boolean;
}
