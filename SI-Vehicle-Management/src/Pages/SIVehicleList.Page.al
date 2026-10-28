page 63250 "SI Vehicle List"
{
    PageType = List;
    SourceTable = "SI Vehicle Profile";
    Caption = 'Транспортні засоби';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "SI Vehicle Card";
    layout
    {
        area(Content)
        {
            repeater(Vehicles)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field("Inventory No."; Rec."Inventory No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Vehicle Type Code"; Rec."Vehicle Type Code") { ApplicationArea = All; }
                field("Registration No."; Rec."Registration No.") { ApplicationArea = All; }
                field(VIN; Rec.VIN) { ApplicationArea = All; }
                field("Ownership Type"; Rec."Ownership Type") { ApplicationArea = All; }
                field("Fixed Asset No."; Rec."Fixed Asset No.") { ApplicationArea = All; }
                field(Blocked; Rec.Blocked) { ApplicationArea = All; }
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
