page 57135 "SI Prok Fact Source FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Джерело Proktek';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(Source)
            {
                ShowCaption = false;
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Formula ID"; Rec."Formula ID") { ApplicationArea = All; }
                field("Formula UUID"; Rec."Formula UUID") { ApplicationArea = All; }
                field("Formula Code"; Rec."Formula Code") { ApplicationArea = All; }
                field("Formula ERP Code"; Rec."Formula ERP Code") { ApplicationArea = All; }
                field("Capture Mode"; Rec."Capture Mode") { ApplicationArea = All; }
            }
        }
    }
}
