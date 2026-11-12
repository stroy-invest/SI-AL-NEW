page 60033 "SI Project Reconcile Log"
{
    PageType = List;
    SourceTable = "SI Project Reconcile Log";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Журнал перевірки проєктів';
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field("Project No."; Rec."Project No.") { ApplicationArea = All; }
                field("Site Code"; Rec."Site Code") { ApplicationArea = All; }
                field(Result; Rec.Result) { ApplicationArea = All; }
                field(Details; Rec.Details) { ApplicationArea = All; }
                field("Run ID"; Rec."Run ID") { ApplicationArea = All; Visible = false; }
            }
        }
    }
}
