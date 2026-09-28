table 55002 "SI Approved Manufacturer Prod."
{
    Caption = 'Схвалений продукт виробника';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = '№ товару';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = Item."No.";
        }

        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Код варіанта';
            DataClassification = CustomerContent;
            TableRelation = "Item Variant".Code
                where("Item No." = field("Item No."));
        }

        field(3; "Manufacturer Product Code"; Code[20])
        {
            Caption = 'Код продукту виробника';
            DataClassification = CustomerContent;
            NotBlank = true;
            TableRelation = "SI Manufacturer Product".Code;

            trigger OnValidate()
            begin
                ValidateApprovalContext();
            end;
        }

        field(4; "Approval Status"; Enum "SI Manufacturer Approval")
        {
            Caption = 'Статус схвалення';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateApprovalContext();
            end;
        }

        field(10; "Item Description"; Text[100])
        {
            Caption = 'Товар';
            FieldClass = FlowField;
            CalcFormula = lookup(
                Item.Description
                where("No." = field("Item No.")));
        }

        field(20; "Variant Description"; Text[100])
        {
            Caption = 'Варіант';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "Item Variant".Description
                where(
                    "Item No." = field("Item No."),
                    Code = field("Variant Code")));
        }

        field(30; "Manufacturer Product Desc."; Text[100])
        {
            Caption = 'Продукт виробника';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Manufacturer Product".Description
                where(Code = field("Manufacturer Product Code")));
        }

        field(40; "Manufacturer Code"; Code[20])
        {
            Caption = 'Код виробника';
            FieldClass = FlowField;
            CalcFormula = lookup(
                "SI Manufacturer Product"."Manufacturer Code"
                where(Code = field("Manufacturer Product Code")));
        }
    }

    keys
    {
        key(PK; "Item No.", "Variant Code", "Manufacturer Product Code")
        {
            Clustered = true;
        }

        key(ManufacturerProduct; "Manufacturer Product Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(
            DropDown;
        "Item No.",
            "Variant Code",
            "Manufacturer Product Code",
            "Approval Status")
        {
        }
    }

    local procedure ValidateApprovalContext()
    var
        Item: Record Item;
        ManufacturerProduct: Record "SI Manufacturer Product";
        ManufacturerMgt: Codeunit "SI Manufacturer Mgt.";
    begin
        if "Approval Status" <> "Approval Status"::Approved then
            exit;

        if ("Item No." = '') or
           ("Manufacturer Product Code" = '')
        then
            exit;

        ManufacturerMgt.ValidateGloballyAvailable(
            "Manufacturer Product Code");

        Item.Get("Item No.");

        ManufacturerProduct.Get(
            "Manufacturer Product Code");

        ManufacturerMgt.ValidateManufacturerForCategory(
            Item."Item Category Code",
            ManufacturerProduct."Manufacturer Code");
    end;
}