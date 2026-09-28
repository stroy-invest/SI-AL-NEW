table 61051 "SI Proc. Plan Trace"
{
    Caption = 'Технічний слід планування закупівель';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10]) { Caption = 'Шаблон'; }
        field(2; "Worksheet Batch Name"; Code[10]) { Caption = 'Пакет'; }
        field(3; "Worksheet Line No."; Integer) { Caption = '№ рядка'; }
        field(4; "Forecast Entry No."; Integer) { Caption = '№ запису прогнозу'; }
        field(10; "Attributed Qty. (Base)"; Decimal) { Caption = 'Віднесена кількість (базова)'; DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Forecast Entry No.") { Clustered = true; }
    }
}
