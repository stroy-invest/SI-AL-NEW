page 63254 "SI Vehicle Capacities"
{
    PageType = ListPart;
    SourceTable = "SI Vehicle Capacity";
    Caption = 'Характеристики';
    ApplicationArea = All;
    DelayedInsert = true;
    layout { area(Content) { repeater(Capacities) {
        field("Capacity Type Code"; Rec."Capacity Type Code") { ApplicationArea = All; }
        field(Quantity; Rec.Quantity) { ApplicationArea = All; }
        field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
    } } }
}
