page 57133 "SI Prok Fact Validation Lines"
{
    PageType = ListPart;
    SourceTable = "SI Prok Fact Validation Entry";
    Caption = 'Діагностика технічної перевірки';
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Rule Code"; Rec."Rule Code") { ApplicationArea = All; }
                field(Severity; Rec.Severity) { ApplicationArea = All; }
                field("Object Type"; Rec."Object Type") { ApplicationArea = All; }
                field("Material Line No."; Rec."Material Line No.") { ApplicationArea = All; }
                field("Diagnostic Message"; Rec."Diagnostic Message") { ApplicationArea = All; }
                field("Checked At"; Rec."Checked At") { ApplicationArea = All; }
            }
        }
    }
}
