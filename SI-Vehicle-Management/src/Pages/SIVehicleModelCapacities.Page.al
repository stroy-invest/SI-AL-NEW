page 63260 "SI Vehicle Model Capacities"
{
    PageType = ListPart;
    SourceTable = "SI Vehicle Model Capacity";
    Caption = 'Характеристики моделі';
    ApplicationArea = All;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            repeater(Capacities)
            {
                field("Capacity Type Code"; Rec."Capacity Type Code") { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            }
        }
    }
}
