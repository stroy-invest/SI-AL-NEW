table 61013 "SI Supply Material Req."
{
    Caption = 'Потреба в матеріалах';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Decision No."; Code[20]) { Caption = '№ рішення'; }
        field(2; "Decision Line No."; Integer) { Caption = '№ рядка рішення'; }
        field(3; "Allocation Line No."; Integer) { Caption = '№ розподілу'; }
        field(4; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Item No."; Code[20]) { Caption = 'Матеріал'; TableRelation = Item."No."; }
        field(11; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(12; Description; Text[100]) { Caption = 'Опис'; }
        field(20; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(21; "Quantity per"; Decimal) { Caption = 'Кількість на базис рецептури'; DecimalPlaces = 0 : 5; }
        field(22; "Required Quantity"; Decimal) { Caption = 'Потрібно'; DecimalPlaces = 0 : 5; }
        field(23; "Available Quantity"; Decimal) { Caption = 'В наявності'; DecimalPlaces = 0 : 5; }
        field(24; "Shortage Quantity"; Decimal) { Caption = 'Дефіцит'; DecimalPlaces = 0 : 5; }
        field(30; "Location Code"; Code[10]) { Caption = 'Склад матеріалів'; TableRelation = Location.Code; }
        field(40; "Recipe No."; Code[50]) { Caption = 'Рецептура'; }
        field(41; "Revision No."; Integer) { Caption = 'Ревізія'; }
        field(50; "Checked At"; DateTime) { Caption = 'Перевірено'; }
        field(60; "Selected Vendor No."; Code[20])
        {
            Caption = 'Вибраний постачальник';
            TableRelation = Vendor."No.";
        }
        field(61; "Procurement Batch No."; Code[20])
        {
            Caption = 'Підготовка закупівлі';
            TableRelation = "SI Procurement Batch"."No.";
            Editable = false;
        }
        field(62; "Selected Vendor Name"; Text[100])
        {
            Caption = 'Вибраний постачальник';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Selected Vendor No.")));
            Editable = false;
        }
        field(63; "Prepared for Procurement"; Boolean)
        {
            Caption = 'Підготовлено до закупівлі';
            FieldClass = FlowField;
            CalcFormula = exist("SI Procurement Line" where(
                "Decision No." = field("Decision No."),
                "Decision Line No." = field("Decision Line No."),
                "Allocation Line No." = field("Allocation Line No."),
                "Requirement Line No." = field("Line No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Decision No.", "Decision Line No.", "Allocation Line No.", "Line No.") { Clustered = true; }
        key(Component; "Item No.", "Variant Code", "Location Code") { }
    }
}
