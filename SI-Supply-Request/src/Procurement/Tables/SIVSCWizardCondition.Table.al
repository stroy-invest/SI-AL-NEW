table 61061 "SI VSC Wizard Condition"
{
    Caption = 'Умова постачання майстра';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { Caption = '№'; }
        field(2; "Category Code"; Code[20]) { Caption = 'Код категорії'; }
        field(3; "Shipment Method Code"; Code[10]) { Caption = 'Спосіб поставки'; TableRelation = "Shipment Method".Code; }
        field(4; "Shipment Method Name"; Text[100]) { Caption = 'Спосіб поставки'; }
        field(5; "Minimum Order Quantity"; Decimal) { Caption = 'Мінімальна кількість замовлення'; DecimalPlaces = 0 : 5; MinValue = 0; }
        field(6; "Order Multiple"; Decimal) { Caption = 'Кратність замовлення'; DecimalPlaces = 0 : 5; MinValue = 0; }
        field(7; "UoM Code"; Code[10]) { Caption = 'Од. виміру'; TableRelation = "Unit of Measure".Code; }
        field(8; "Lead Time Calculation"; DateFormula) { Caption = 'Строк постачання'; }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } key(Category; "Category Code", "Entry No.") { } }
}
