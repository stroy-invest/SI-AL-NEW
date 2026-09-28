table 61054 "SI PO Proposal Line"
{
    Caption = 'Рядок пропозиції замовлення';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Proposal Entry No."; Integer) { Caption = 'Пропозиція'; TableRelation = "SI PO Proposal Header"."Entry No."; }
        field(2; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Item No."; Code[20]) { Caption = 'Товар / матеріал'; TableRelation = Item."No."; }
        field(11; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(12; Description; Text[100]) { Caption = 'Опис'; }
        field(13; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; TableRelation = "Unit of Measure".Code; }
        field(14; Quantity; Decimal) { Caption = 'Кількість'; DecimalPlaces = 0 : 5; }
        field(15; "Location Code"; Code[10]) { Caption = 'Склад'; TableRelation = Location.Code; }
        field(16; "Capability Code"; Code[20]) { Caption = 'Канал постачання'; TableRelation = "SI Vendor Supply Capability".Code; }
        field(20; "Purchase Order No."; Code[20]) { Caption = 'Замовлення постачальнику'; Editable = false; }
        field(21; "Purchase Line No."; Integer) { Caption = 'Рядок замовлення'; Editable = false; }
    }

    keys
    {
        key(PK; "Proposal Entry No.", "Line No.") { Clustered = true; }
        key(Aggregation; "Proposal Entry No.", "Item No.", "Variant Code", "Unit of Measure Code", "Location Code", "Capability Code") { }
    }
}
