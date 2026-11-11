page 57144 "SI Prok Shipments"
{
    PageType = List;
    SourceTable = "SI Prok Shipment";
    CardPageId = "SI Prok Shipment Card";
    Caption = 'Документи відвантаження бетону';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Shipments)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Source Order No."; Rec."Source Order No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Quantity M3"; Rec."Quantity M3") { ApplicationArea = All; }
                field("Truck Plate"; Rec."Truck Plate") { ApplicationArea = All; }
                field("Driver Name"; Rec."Driver Name") { ApplicationArea = All; }
                field("Shipment Date/Time"; Rec."Shipment Date/Time") { ApplicationArea = All; }
            }
        }
    }
}
