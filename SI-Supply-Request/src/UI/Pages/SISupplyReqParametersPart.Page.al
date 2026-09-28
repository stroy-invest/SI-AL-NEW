page 61004 "SI Supply Req Parameters Part"
{
    PageType = ListPart;
    SourceTable = "SI Supply Req Parameter";
    ApplicationArea = All;
    Caption = 'Додаткові параметри';
    AutoSplitKey = false;

    layout
    {
        area(Content)
        {
            repeater(Parameters)
            {
                field("Request Line No."; Rec."Request Line No.") { ApplicationArea = All; }
                field("Parameter Code"; Rec."Parameter Code") { ApplicationArea = All; }
                field("Value Type"; Rec."Value Type") { ApplicationArea = All; }
                field("Requested Code Value"; Rec."Requested Code Value") { ApplicationArea = All; }
                field("Requested Decimal Value"; Rec."Requested Decimal Value") { ApplicationArea = All; }
                field("Requested Text Value"; Rec."Requested Text Value") { ApplicationArea = All; }
                field("Requested Bool Value"; Rec."Requested Bool Value") { ApplicationArea = All; }
                field("Requested Date Value"; Rec."Requested Date Value") { ApplicationArea = All; }
                field("Requested DateTime Value"; Rec."Requested DateTime Value") { ApplicationArea = All; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { ApplicationArea = All; }
                field(Source; Rec.Source) { ApplicationArea = All; Editable = false; }
            }
        }
    }
}
