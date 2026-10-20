page 70024 "SI Audit Addresses"
{
    PageType = List;
    SourceTable = "SI Audit BP Address";
    Caption = 'SI Audit Addresses';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Business Partner No."; Rec."Business Partner No.") { ApplicationArea = All; }
                field("Address Type"; Rec."Address Type") { ApplicationArea = All; }
                field("Raw Address"; Rec."Raw Address") { ApplicationArea = All; }
                field(City; Rec.City) { ApplicationArea = All; }
                field(Street; Rec.Street) { ApplicationArea = All; }
            }
        }
    }
}
