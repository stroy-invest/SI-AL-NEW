page 57093 "SI Prok Production Fact Card"
{
    PageType = Card;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факт виробництва Proktek';
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Загальне';
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Ready for Posting"; Rec."Ready for Posting") { ApplicationArea = All; }
                field("Validation Message"; Rec."Validation Message") { ApplicationArea = All; }
            }
            group(Correlation)
            {
                Caption = 'Кореляція';
                field("Order ID"; Rec."Order ID") { ApplicationArea = All; }
                field("Order UUID"; Rec."Order UUID") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field("Supply Decision No."; Rec."Supply Decision No.") { ApplicationArea = All; }
                field("Supply Decision Line No."; Rec."Supply Decision Line No.") { ApplicationArea = All; }
                field("Supply Allocation Line No."; Rec."Supply Allocation Line No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Formula UUID"; Rec."Formula UUID") { ApplicationArea = All; }
            }
            group(Quantity)
            {
                Caption = 'Кількість';
                field("Ordered Quantity M3"; Rec."Ordered Quantity M3") { ApplicationArea = All; }
                field("Produced Quantity M3"; Rec."Produced Quantity M3") { ApplicationArea = All; }
                field("Order Produced Total M3"; Rec."Order Produced Total M3") { ApplicationArea = All; }
                field("Order Remaining M3"; Rec."Order Remaining M3") { ApplicationArea = All; }
            }
            part(Materials; "SI Prok Prod Fact Materials")
            {
                ApplicationArea = All;
                SubPageLink = "Production Fact Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewCanonicalJson)
            {
                ApplicationArea = All;
                Caption = 'Canonical JSON';
                Image = View;
                trigger OnAction()
                var
                    JsonText: Text;
                begin
                    JsonText := Rec.GetCanonicalJson();
                    Message('%1', JsonText);
                end;
            }
        }
    }
}
