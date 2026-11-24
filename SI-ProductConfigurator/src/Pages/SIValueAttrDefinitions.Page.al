page 53039 "SI Value Attr. Definitions"
{
    PageType = List;
    SourceTable = "SI Value Attr. Definition";
    ApplicationArea = All;
    Caption = 'Визначення характеристик';
    DelayedInsert = true;
    PopulateAllFields = true;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Parameter Code"; Rec."Parameter Code") { ApplicationArea = All; }
                field("Code"; Rec."Code") { ApplicationArea = All; }
                field("Description"; Rec."Description") { ApplicationArea = All; }
                field("Value Type"; Rec."Value Type") { ApplicationArea = All; }
                field("Semantic Code"; Rec."Semantic Code") { ApplicationArea = All; }
                field("UoM Code"; Rec."UoM Code") { ApplicationArea = All; }
                field("Sort Order"; Rec."Sort Order") { ApplicationArea = All; }
            }
        }
    }
}
