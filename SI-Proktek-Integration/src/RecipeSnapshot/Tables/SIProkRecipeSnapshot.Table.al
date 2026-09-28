table 57020 "SI Prok Recipe Snapshot"
{
    Caption = 'SI Proktek Recipe Snapshot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Товар';
            TableRelation = Item."No.";

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then
                    Clear("Variant Code");
                RefreshBaseData();
            end;
        }
        field(20; "Variant Code"; Code[10])
        {
            Caption = 'Варіант';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then
                    ItemVariant.Get("Item No.", "Variant Code");
                RefreshBaseData();
            end;
        }
        field(30; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM';
            Editable = false;
        }
        field(40; Description; Text[100])
        {
            Caption = 'Назва snapshot';
        }
        field(50; "Base Formula Code"; Text[100])
        {
            Caption = 'Base Formula Code';
            Editable = false;
        }
        field(60; "Derived Formula Code"; Text[150])
        {
            Caption = 'Derived Formula Code';
            Editable = false;
        }
        field(70; "Proktek Formula Index"; BigInteger)
        {
            Caption = 'Proktek Formula Index';
            Editable = false;
        }
        field(80; "Proktek Formula UUID"; Guid)
        {
            Caption = 'Proktek Formula UUID';
            Editable = false;
        }
        field(90; "Production Request Entry No."; Integer)
        {
            Caption = 'Production Request';
            Editable = false;
            TableRelation = "SI Concrete Prod Request"."Entry No.";
        }
        field(100; Status; Enum "SI Prok Recipe Snap Status")
        {
            Caption = 'Статус';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ProductionRequest; "Production Request Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Item No." <> '' then
            RefreshBaseData();
    end;

    procedure RefreshBaseData()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        BOMResolver: Codeunit "SI Prok Product BOM Resolver";
        FormulaProjector: Codeunit "SI Prok Formula Projector";
        BaseName: Text[100];
    begin
        if "Item No." = '' then begin
            Clear("Production BOM No.");
            Clear("Base Formula Code");
            Clear("Derived Formula Code");
            exit;
        end;

        Item.Get("Item No.");
        "Production BOM No." := BOMResolver.ResolveProductionBOM("Item No.", "Variant Code");
        "Base Formula Code" := CopyStr(FormulaProjector.BuildFormulaIntegrationKey("Item No.", "Variant Code"), 1, MaxStrLen("Base Formula Code"));

        BaseName := Item.Description;
        if "Variant Code" <> '' then begin
            ItemVariant.Get("Item No.", "Variant Code");
            if ItemVariant.Description <> '' then
                BaseName := ItemVariant.Description;
        end;
        if Description = '' then
            Description := BaseName;

        if "Entry No." <> 0 then
            "Derived Formula Code" := CopyStr(StrSubstNo('%1|RS-%2', "Base Formula Code", "Entry No."), 1, MaxStrLen("Derived Formula Code"));
    end;
}
