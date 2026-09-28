table 61043 "SI VSC Candidate"
{
    Caption = 'Кандидат каналу постачання';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Capability Code"; Code[20]) { Caption = 'Код каналу'; }
        field(2; "Capability Description"; Text[100]) { Caption = 'Канал постачання'; }
        field(3; "Vendor No."; Code[20]) { Caption = '№ постачальника'; }
        field(4; "Vendor Name"; Text[100]) { Caption = 'Постачальник'; }
        field(5; "Matched Category Code"; Code[20]) { Caption = 'Категорія відповідності'; }
        field(6; "Matched Category Description"; Text[100]) { Caption = 'Категорія відповідності'; }
        field(7; "Category Distance"; Integer) { Caption = 'Рівень успадкування'; }
        field(8; "Shipment Method Code"; Code[10]) { Caption = 'Спосіб поставки'; }
        field(9; "UoM Code"; Code[10]) { Caption = 'Од. виміру'; }
        field(10; "Minimum Order Quantity"; Decimal) { Caption = 'Мін. кількість'; DecimalPlaces = 0 : 5; }
        field(11; "Order Multiple"; Decimal) { Caption = 'Кратність'; DecimalPlaces = 0 : 5; }
        field(12; "Requested Quantity"; Decimal) { Caption = 'Потреба'; DecimalPlaces = 0 : 5; }
        field(13; "Suggested Purchase Quantity"; Decimal) { Caption = 'Рекомендована кількість'; DecimalPlaces = 0 : 5; }
        field(14; "Lead Time Calculation"; DateFormula) { Caption = 'Строк постачання'; }
        field(15; "Earliest Delivery Date"; Date) { Caption = 'Найраніша дата поставки'; }
        field(16; "Required Date"; Date) { Caption = 'Потрібно на дату'; }
        field(17; "Manufacturer Restricted"; Boolean) { Caption = 'Є обмеження виробника'; }
        field(18; "Manufacturer Code"; Code[20]) { Caption = 'Виробник запиту'; }
        field(19; "Shipment Method Description"; Text[100]) { Caption = 'Спосіб поставки'; }
    }

    keys
    {
        key(PK; "Capability Code") { Clustered = true; }
        key(Specificity; "Category Distance", "Vendor No.", "Capability Code") { }
    }
}
