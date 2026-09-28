page 61001 "SI Supply Req Lines"
{
    PageType = ListPart;
    SourceTable = "SI Supply Req Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    MultipleNewLines = true;
    ApplicationArea = All;
    Caption = 'Позиції потреби';

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line Type"; Rec."Line Type") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Requested Quantity"; Rec."Requested Quantity") { ApplicationArea = All; }
                field("Approved Quantity"; Rec."Approved Quantity") { ApplicationArea = All; Editable = false; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field("Required on Site At"; Rec."Required on Site At") { ApplicationArea = All; ShowMandatory = true; }
                field(Comment; Rec.Comment) { ApplicationArea = All; }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.ApplyHeaderDefaults();
    end;
}
