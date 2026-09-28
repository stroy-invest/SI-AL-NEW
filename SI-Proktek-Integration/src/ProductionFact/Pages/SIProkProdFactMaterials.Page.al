page 57092 "SI Prok Prod Fact Materials"
{
    PageType = ListPart;
    SourceTable = "SI Prok Prod Fact Material";
    Caption = 'Матеріали';
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Material Name"; Rec."Material Name") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Requested Kg"; Rec."Requested Kg") { ApplicationArea = All; }
                field("Adjusted Kg"; Rec."Adjusted Kg") { ApplicationArea = All; }
                field("Actual Kg"; Rec."Actual Kg") { ApplicationArea = All; }
                field("Variance Kg"; Rec."Variance Kg") { ApplicationArea = All; }
                field("Variance %"; Rec."Variance %") { ApplicationArea = All; }
            }
        }
    }
}
