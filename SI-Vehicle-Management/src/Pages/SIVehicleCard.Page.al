page 63251 "SI Vehicle Card"
{
    PageType = Card;
    SourceTable = "SI Vehicle Profile";
    Caption = 'Картка транспортного засобу';
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Основне';
                field("No."; Rec."No.") { ApplicationArea = All; Editable = false; }
                field("Inventory No."; Rec."Inventory No.") { ApplicationArea = All; }
                field("Brand Code"; Rec."Brand Code") { ApplicationArea = All; }
                field("Model Code"; Rec."Model Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Search Description"; Rec."Search Description") { ApplicationArea = All; }
                field("Vehicle Type Code"; Rec."Vehicle Type Code") { ApplicationArea = All; }
                field("Registration No."; Rec."Registration No.") { ApplicationArea = All; }
                field(VIN; Rec.VIN) { ApplicationArea = All; }
                field("Ownership Type"; Rec."Ownership Type") { ApplicationArea = All; }
                field("Fixed Asset No."; Rec."Fixed Asset No.") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
            }
            part(Capacities; "SI Vehicle Capacities")
            {
                ApplicationArea = All;
                SubPageLink = "Vehicle No." = field("No.");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(CheckOperationalUse)
            {
                Caption = 'Перевірити готовність до використання';
                ApplicationArea = All;
                Image = Check;
                trigger OnAction()
                var Mgt: Codeunit "SI Vehicle Management";
                begin
                    Mgt.AssertOperationallyUsable(Rec."No.");
                    Message('Транспортний засіб %1 готовий до операційного використання.', Rec."No.");
                end;
            }
        }
    }
}
