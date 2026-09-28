page 57091 "SI Prok Production Facts"
{
    PageType = List;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Факти виробництва Proktek';
    ApplicationArea = All;
    UsageCategory = Tasks;
    CardPageId = "SI Prok Production Fact Card";
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Facts)
            {
                field("Production Date/Time"; Rec."Production Date/Time") { ApplicationArea = All; }
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Produced Quantity M3"; Rec."Produced Quantity M3") { ApplicationArea = All; }
                field("Order Produced Total M3"; Rec."Order Produced Total M3") { ApplicationArea = All; }
                field("Order Remaining M3"; Rec."Order Remaining M3") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Ready for Posting"; Rec."Ready for Posting") { ApplicationArea = All; }
            }
        }
    }
}
