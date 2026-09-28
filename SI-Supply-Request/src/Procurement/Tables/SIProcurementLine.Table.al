table 61016 "SI Procurement Line"
{
    Caption = 'Рядок підготовки закупівлі';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Batch No."; Code[20]) { Caption = '№ підготовки'; TableRelation = "SI Procurement Batch"."No."; }
        field(2; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Vendor No."; Code[20]) { Caption = '№ постачальника'; TableRelation = Vendor."No."; }
        field(11; "Vendor Name"; Text[100])
        {
            Caption = 'Постачальник';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(20; "Item No."; Code[20]) { Caption = 'Матеріал'; TableRelation = Item."No."; }
        field(21; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(22; Description; Text[100]) { Caption = 'Опис'; }
        field(23; "Item Category Code"; Code[20]) { Caption = 'Категорія'; TableRelation = "Item Category".Code; }
        field(30; Quantity; Decimal) { Caption = 'До закупівлі'; DecimalPlaces = 0 : 5; }
        field(31; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(32; "Location Code"; Code[10]) { Caption = 'Склад'; TableRelation = Location.Code; }
        field(40; "Decision No."; Code[20]) { Caption = '№ рішення'; }
        field(41; "Decision Line No."; Integer) { Caption = '№ рядка рішення'; }
        field(42; "Allocation Line No."; Integer) { Caption = '№ розподілу'; }
        field(43; "Requirement Line No."; Integer) { Caption = '№ рядка потреби'; }
        field(50; "Added By User ID"; Text[50]) { Caption = 'Додав'; Editable = false; }
        field(51; "Added At"; DateTime) { Caption = 'Додано'; Editable = false; }
    }

    keys
    {
        key(PK; "Batch No.", "Line No.") { Clustered = true; }
        key(VendorView; "Batch No.", "Vendor No.", "Item No.") { }
        key(SourceRequirement; "Decision No.", "Decision Line No.", "Allocation Line No.", "Requirement Line No.") { }
    }
}
