page 57021 "SI Prok Recipe Snapshot Lines"
{
    PageType = ListPart;
    SourceTable = "SI Prok Recipe Snapshot Line";
    Caption = 'Модифікатори рецептури';
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field(Quantity; Rec.Quantity) { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
            }
        }
    }
}
