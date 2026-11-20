page 54063 "SI BP ERP Projections"
{
    PageType = List;
    SourceTable = "SI BP ERP Projection";
    Caption = 'ERP-проєкції';
    ApplicationArea = All;
    UsageCategory = Lists;
    CardPageId = "SI BP Projection Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Projections)
            {
                field("Role Code"; Rec."Role Code") { ApplicationArea = All; }
                field("Business Partner No."; Rec."Business Partner No.") { ApplicationArea = All; }
                field("Business Partner Name"; Rec."Business Partner Name") { ApplicationArea = All; }
                field("Role Type"; Rec."Role Type") { ApplicationArea = All; }
                field(Status; Rec.Status) { ApplicationArea = All; }
                field("ERP No."; Rec."ERP No.") { ApplicationArea = All; }
                field("Error Message"; Rec."Error Message") { ApplicationArea = All; }
            }
        }
    }
}
