table 61040 "SI Planning PoC Projection"
{
    Caption = 'Planning PoC Projection';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Decision No."; Code[20]) { Caption = '№ рішення'; }
        field(2; "Decision Line No."; Integer) { Caption = '№ рядка рішення'; }
        field(3; "Allocation Line No."; Integer) { Caption = '№ розподілу'; }
        field(4; "Requirement Line No."; Integer) { Caption = '№ рядка потреби'; }
        field(10; "Forecast Name"; Code[10])
        {
            Caption = 'Прогноз попиту';
            TableRelation = "Production Forecast Name".Name;
        }
        field(11; "Forecast Entry No."; Integer) { Caption = '№ запису прогнозу'; }
        field(20; "Item No."; Code[20]) { Caption = 'Матеріал'; }
        field(21; "Variant Code"; Code[10]) { Caption = 'Варіант'; }
        field(22; "Location Code"; Code[10]) { Caption = 'Склад'; }
        field(23; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(24; "Forecast Date"; Date) { Caption = 'Дата прогнозу'; }
        field(25; "Projected Quantity"; Decimal) { Caption = 'Спроєктована кількість'; DecimalPlaces = 0 : 5; }
        field(30; "Projected At"; DateTime) { Caption = 'Спроєктовано'; }
    }

    keys
    {
        key(PK; "Decision No.", "Decision Line No.", "Allocation Line No.", "Requirement Line No.") { Clustered = true; }
        key(ForecastEntry; "Forecast Name", "Forecast Entry No.") { Unique = true; }
    }
}
