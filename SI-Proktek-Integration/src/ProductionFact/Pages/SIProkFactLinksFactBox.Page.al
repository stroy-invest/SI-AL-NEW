page 57136 "SI Prok Fact Links FactBox"
{
    PageType = CardPart;
    SourceTable = "SI Prok Production Fact";
    Caption = 'Зв’язки BC';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            group(Links)
            {
                ShowCaption = false;
                field("Production BOM No."; Rec."Production BOM No.") { ApplicationArea = All; }
                field("Production BOM Version Code"; Rec."Production BOM Version Code") { ApplicationArea = All; }
                field("Recipe No."; Rec."Recipe No.") { ApplicationArea = All; }
                field("Recipe Revision No."; Rec."Recipe Revision No.") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Order No."; Rec."Order No.") { ApplicationArea = All; Caption = 'Замовлення №'; }
                field("Supply Decision No."; Rec."Supply Decision No.") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
            }
        }
    }
}
