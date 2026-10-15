table 57096 "SI Prok Sim Truck Batch"
{
    Caption = 'Тестова партія Proktek (автоміксер)';
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Order UUID"; Guid) { Caption = 'Proktek Order UUID'; }
        field(2; "Truck No."; Integer) { Caption = '№ автоміксера'; }
        field(3; "Truck Code"; Code[30]) { Caption = 'Автоміксер'; }
        field(4; "Truck Capacity M3"; Decimal) { Caption = 'Місткість, м³'; }
        field(5; "Supply Request No."; Code[30]) { Caption = 'Заявка'; }
        field(6; "Mix Count"; Integer) { Caption = 'Замісів'; }
        field(7; "Produced M3"; Decimal) { Caption = 'Випуск, м³'; DecimalPlaces = 0 : 5; }
    }
    keys { key(PK; "Order UUID", "Truck No.") { Clustered = true; } }
}
