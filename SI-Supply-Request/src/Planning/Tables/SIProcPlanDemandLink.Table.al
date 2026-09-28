table 61050 "SI Proc. Plan Demand Link"
{
    Caption = 'Зв’язки плану закупівель із потребами';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Run No."; Integer) { Caption = '№ запуску'; TableRelation = "SI Proc. Plan Run"."Run No."; }
        field(2; "Snapshot Line No."; Integer) { Caption = '№ рядка знімка'; }
        field(3; "Planning Demand Entry No."; Integer) { Caption = '№ планової потреби'; TableRelation = "SI Planning Demand"."Entry No."; }
        field(10; "Forecast Entry No."; Integer) { Caption = '№ запису прогнозу'; }
        field(20; "Attributed Quantity"; Decimal) { Caption = 'Кількість, покрита закупівлею'; DecimalPlaces = 0 : 5; }
        field(21; "Attributed Qty. (Base)"; Decimal) { Caption = 'Кількість, покрита закупівлею (базова)'; DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; "Run No.", "Snapshot Line No.", "Planning Demand Entry No.") { Clustered = true; }
        key(Demand; "Planning Demand Entry No.", "Run No.") { }
    }
}
