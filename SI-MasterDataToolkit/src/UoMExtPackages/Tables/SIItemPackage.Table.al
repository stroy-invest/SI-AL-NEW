table 58001 "SI Item Package"
{
    Caption = 'Паковання товарів';
    DataClassification = CustomerContent;
    LookupPageId = "SI Item Packages";
    DrillDownPageId = "SI Item Packages";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "Item No." = xRec."Item No." then
                    exit;

                Validate("Variant Code", '');
                Clear(Code);
                Clear("Item UoM Code");
                Clear(Description);
            end;
        }

        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }

        field(3; "Line No."; Integer)
        {
            Caption = '№ рядка';
        }

        field(4; "Package Type Code"; Code[20])
        {
            Caption = 'Тип паковання';
            TableRelation = "SI Package Type".Code where(Blocked = const(false));

            trigger OnValidate()
            var
                PackageType: Record "SI Package Type";
                ItemPackageMgt: Codeunit "SI Item Package Mgt.";
            begin
                if "Package Type Code" = '' then begin
                    Clear(Code);
                    Clear("Item UoM Code");
                    exit;
                end;

                PackageType.Get("Package Type Code");
                if Description = '' then
                    Description := PackageType.Description;

                ItemPackageMgt.RefreshGeneratedFields(Rec);
                ItemPackageMgt.SyncStandardItemUoM(Rec);
            end;
        }

        field(5; Quantity; Decimal)
        {
            Caption = 'Кількість у пакованні';
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            var
                ItemPackageMgt: Codeunit "SI Item Package Mgt.";
            begin
                if Quantity < 0 then
                    Error('Кількість у пакованні не може бути від’ємною.');

                ItemPackageMgt.RefreshGeneratedFields(Rec);
                ItemPackageMgt.SyncStandardItemUoM(Rec);
            end;
        }

        field(6; "UoM Code"; Code[10])
        {
            Caption = 'Одиниця вимірювання вмісту';
            TableRelation = "Unit of Measure".Code where("SI Blocked" = const(false));

            trigger OnValidate()
            var
                ItemPackageMgt: Codeunit "SI Item Package Mgt.";
            begin
                if "UoM Code" <> '' then
                    ItemPackageMgt.ValidatePackageContentUoM(Rec);

                ItemPackageMgt.RefreshGeneratedFields(Rec);
                ItemPackageMgt.SyncStandardItemUoM(Rec);
            end;
        }

        field(7; Description; Text[150])
        {
            Caption = 'Опис';
        }

        field(8; Default; Boolean)
        {
            Caption = 'За замовчуванням (застаріле)';
            ObsoleteState = Pending;
            ObsoleteReason = 'Замінено окремими ознаками для закупівлі, продажу та складу.';
            ObsoleteTag = '1.0';
        }

        field(9; Blocked; Boolean)
        {
            Caption = 'Не використовується';

            trigger OnValidate()
            begin
                if not Blocked then
                    exit;

                "Default Purchase" := false;
                "Default Sales" := false;
                "Default Warehouse" := false;
            end;
        }

        field(10; "Item UoM Code"; Code[10])
        {
            Caption = 'Код одиниці паковання (BC)';
            Editable = false;
        }

        field(11; "External Code"; Code[50])
        {
            Caption = 'Зовнішній код';
        }

        field(12; Code; Code[20])
        {
            Caption = 'Код паковання';
            Editable = false;
        }

        field(13; "Quantity per Package"; Decimal)
        {
            Caption = 'Коефіцієнт BC';
            FieldClass = FlowField;
            Editable = false;
            DecimalPlaces = 0 : 10;
            CalcFormula = lookup(
                "Item Unit of Measure"."Qty. per Unit of Measure"
                where(
                    "Item No." = field("Item No."),
                    Code = field("Item UoM Code")));
        }

        field(14; "Base UoM Code"; Code[10])
        {
            Caption = 'Базова одиниця товару';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = lookup(Item."Base Unit of Measure" where("No." = field("Item No.")));
        }

        field(15; "Default Purchase"; Boolean)
        {
            Caption = 'За замовчуванням для закупівлі';

            trigger OnValidate()
            begin
                if "Default Purchase" then begin
                    TestField(Blocked, false);
                    ClearOtherDefaults(FieldNo("Default Purchase"));
                end;
            end;
        }

        field(16; "Default Sales"; Boolean)
        {
            Caption = 'За замовчуванням для продажу';

            trigger OnValidate()
            begin
                if "Default Sales" then begin
                    TestField(Blocked, false);
                    ClearOtherDefaults(FieldNo("Default Sales"));
                end;
            end;
        }

        field(17; "Default Warehouse"; Boolean)
        {
            Caption = 'За замовчуванням для складу';

            trigger OnValidate()
            begin
                if "Default Warehouse" then begin
                    TestField(Blocked, false);
                    ClearOtherDefaults(FieldNo("Default Warehouse"));
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Item No.", "Variant Code", "Line No.")
        {
            Clustered = true;
        }
        key(PackageCode; "Item No.", "Variant Code", Code)
        {
        }
        key(ItemUoM; "Item No.", "Variant Code", "Item UoM Code")
        {
        }
        key(PackageType; "Package Type Code")
        {
        }
    }

    trigger OnInsert()
    var
        ItemPackageMgt: Codeunit "SI Item Package Mgt.";
    begin
        AssignLineNo();
        ItemPackageMgt.RefreshGeneratedFields(Rec);
        CheckDuplicateCode();
        CheckDuplicateItemUoM();
    end;

    trigger OnModify()
    begin
        CheckDuplicateCode();
        CheckDuplicateItemUoM();
    end;

    local procedure AssignLineNo()
    var
        ItemPackage: Record "SI Item Package";
    begin
        if "Line No." <> 0 then
            exit;

        ItemPackage.SetRange("Item No.", "Item No.");
        ItemPackage.SetRange("Variant Code", "Variant Code");

        if ItemPackage.FindLast() then
            "Line No." := ItemPackage."Line No." + 10000
        else
            "Line No." := 10000;
    end;

    local procedure CheckDuplicateCode()
    var
        ItemPackage: Record "SI Item Package";
    begin
        if ("Item No." = '') or (Code = '') then
            exit;

        ItemPackage.SetRange("Item No.", "Item No.");
        ItemPackage.SetRange("Variant Code", "Variant Code");
        ItemPackage.SetRange(Code, Code);
        ItemPackage.SetFilter("Line No.", '<>%1', "Line No.");

        if not ItemPackage.IsEmpty() then
            Error(
                'Паковання з кодом %1 уже існує для товару %2 і варіанта %3.',
                Code,
                "Item No.",
                "Variant Code");
    end;

    local procedure CheckDuplicateItemUoM()
    var
        ItemPackage: Record "SI Item Package";
    begin
        if ("Item No." = '') or ("Item UoM Code" = '') then
            exit;

        ItemPackage.SetRange("Item No.", "Item No.");
        ItemPackage.SetRange("Variant Code", "Variant Code");
        ItemPackage.SetRange("Item UoM Code", "Item UoM Code");
        ItemPackage.SetRange(Blocked, false);
        ItemPackage.SetFilter("Line No.", '<>%1', "Line No.");

        if not ItemPackage.IsEmpty() then
            Error(
                'Код одиниці паковання %1 вже використовується іншим активним пакованням товару %2.',
                "Item UoM Code",
                "Item No.");
    end;

    local procedure ClearOtherDefaults(DefaultFieldNo: Integer)
    var
        ItemPackage: Record "SI Item Package";
    begin
        if "Item No." = '' then
            exit;

        ItemPackage.SetRange("Item No.", "Item No.");
        ItemPackage.SetRange("Variant Code", "Variant Code");
        ItemPackage.SetFilter("Line No.", '<>%1', "Line No.");

        case DefaultFieldNo of
            FieldNo("Default Purchase"):
                ItemPackage.ModifyAll("Default Purchase", false);
            FieldNo("Default Sales"):
                ItemPackage.ModifyAll("Default Sales", false);
            FieldNo("Default Warehouse"):
                ItemPackage.ModifyAll("Default Warehouse", false);
        end;
    end;
}
