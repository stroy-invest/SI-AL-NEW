table 61045 "SI Planning Forecast Proj."
{
    Caption = 'Проєкції планових потреб у прогноз';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Planning Demand Entry No."; Integer)
        {
            Caption = '№ планової потреби';
            TableRelation = "SI Planning Demand"."Entry No.";
        }
        field(10; "Forecast Name"; Code[10]) { Caption = 'Прогноз'; }
        field(11; "Forecast Entry No."; Integer) { Caption = '№ запису прогнозу'; }
        field(20; "Item No."; Code[20]) { Caption = 'Товар / матеріал'; }
        field(21; "Variant Code"; Code[10]) { Caption = 'Варіант'; }
        field(22; "Location Code"; Code[10]) { Caption = 'Склад'; }
        field(23; "Unit of Measure Code"; Code[10]) { Caption = 'Од. вим.'; }
        field(24; "Forecast Date"; Date) { Caption = 'Дата прогнозу'; }
        field(25; "Projected Quantity"; Decimal) { Caption = 'Спроєктована кількість'; DecimalPlaces = 0 : 5; }
        field(30; "Projected At"; DateTime) { Caption = 'Спроєктовано'; }
        field(31; "Sync Token"; Guid) { Caption = 'Токен синхронізації'; }
    }

    keys
    {
        key(PK; "Planning Demand Entry No.") { Clustered = true; }
        key(ForecastEntry; "Forecast Entry No.") { Unique = true; }
    }
}
