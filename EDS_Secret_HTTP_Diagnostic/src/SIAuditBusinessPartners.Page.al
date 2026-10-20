page 70023 "SI Audit Business Partners"
{
    PageType = List;
    SourceTable = "SI Audit BP";
    Caption = 'SI Audit Business Partners';
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Registration No."; Rec."Registration No.") { ApplicationArea = All; }
                field("Registry Legal Name"; Rec."Registry Legal Name") { ApplicationArea = All; }
                field("Registry Short Name"; Rec."Registry Short Name") { ApplicationArea = All; }
                field("Registry Status"; Rec."Registry Status") { ApplicationArea = All; }
            }
        }
    }
}
