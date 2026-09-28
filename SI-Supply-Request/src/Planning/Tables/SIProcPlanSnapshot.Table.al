table 61049 "SI Proc. Plan Snapshot"
{
    Caption = 'Знімок плану закупівель';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run No."; Integer) { Caption = '№ запуску'; TableRelation = "SI Proc. Plan Run"."Run No."; }
        field(2; "Line No."; Integer) { Caption = '№ рядка'; }
        field(10; "Req. Worksheet Line No."; Integer) { Caption = '№ рядка стандартного плану'; }
        field(20; "Item No."; Code[20]) { Caption = 'Товар / матеріал'; TableRelation = Item."No."; }
        field(21; "Variant Code"; Code[10]) { Caption = 'Варіант'; TableRelation = "Item Variant".Code where("Item No." = field("Item No.")); }
        field(22; Description; Text[100]) { Caption = 'Опис'; }
        field(23; "Location Code"; Code[10]) { Caption = 'Склад'; TableRelation = Location.Code; }
        field(24; Quantity; Decimal) { Caption = 'Треба закупити'; DecimalPlaces = 0 : 5; }
        field(25; "Quantity (Base)"; Decimal) { Caption = 'Кількість (базова)'; DecimalPlaces = 0 : 5; }
        field(26; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(30; "Due Date"; Date) { Caption = 'Забезпечити до'; }
        field(31; "Order Date"; Date) { Caption = 'Дата замовлення'; }
        field(40; "Action Message"; Enum "Action Message Type") { Caption = 'Дія'; }
        field(41; "Vendor No."; Code[20]) { Caption = 'Постачальник'; TableRelation = Vendor."No."; }
        field(50; "Demand Quantity"; Decimal) { Caption = 'Потреба BC'; DecimalPlaces = 0 : 5; }
        field(51; "Demand Quantity (Base)"; Decimal) { Caption = 'Потреба BC (базова)'; DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Run No.", "Line No.") { Clustered = true; }
        key(ItemDate; "Run No.", "Item No.", "Variant Code", "Location Code", "Due Date") { }
    }
}
