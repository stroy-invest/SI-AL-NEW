page 65005 "SI IW Vehicle Sync Outbox"
{
    PageType = List;
    SourceTable = "SI IW Vehicle Sync Outbox";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'SI IW: Черга синхронізації ТЗ';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Vehicle No."; Rec."Vehicle No.") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("Revision No."; Rec."Revision No.") { ApplicationArea = All; }
                field("Attempt Count"; Rec."Attempt Count") { ApplicationArea = All; }
                field("Next Attempt At"; Rec."Next Attempt At") { ApplicationArea = All; }
                field("Last Attempt At"; Rec."Last Attempt At") { ApplicationArea = All; }
                field("Last Success At"; Rec."Last Success At") { ApplicationArea = All; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Modified At"; Rec."Modified At") { ApplicationArea = All; }
            }
        }
    }
}
