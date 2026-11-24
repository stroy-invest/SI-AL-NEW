page 57964 "SI Prok Sim Fact Del Audit"
{
    PageType = List;
    SourceTable = "SI Prok Sim Fact Del Audit";
    Caption = 'Аудит видалення фактів Proktek';
    ApplicationArea = All;
    UsageCategory = None;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field("Fact Entry No."; Rec."Fact Entry No.") { ApplicationArea = All; }
                field("Production ID"; Rec."Production ID") { ApplicationArea = All; }
                field("Production UUID"; Rec."Production UUID") { ApplicationArea = All; }
                field("Connection Code"; Rec."Connection Code") { ApplicationArea = All; }
                field("Deleted At"; Rec."Deleted At") { ApplicationArea = All; }
                field("Deleted By"; Rec."Deleted By") { ApplicationArea = All; }
                field("Material Lines Deleted"; Rec."Material Lines Deleted") { ApplicationArea = All; }
                field("Validation Lines Deleted"; Rec."Validation Lines Deleted") { ApplicationArea = All; }
            }
        }
    }
}
