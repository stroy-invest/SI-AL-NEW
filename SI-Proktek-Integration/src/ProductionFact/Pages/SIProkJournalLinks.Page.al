page 57142 "SI Prok Journal Links"
{
    PageType = List;
    SourceTable = "SI Prok Journal Link";
    Caption = 'Зв’язки журналів Proktek';
    ApplicationArea = All;
    Editable = false;
    layout
    {
        area(Content)
        {
            repeater(Links)
            {
                field("Fact Entry No."; Rec."Fact Entry No.") { ApplicationArea = All; }
                field("Material Line No."; Rec."Material Line No.") { ApplicationArea = All; }
                field("Journal Template"; Rec."Journal Template") { ApplicationArea = All; }
                field("Journal Batch"; Rec."Journal Batch") { ApplicationArea = All; }
                field("Journal Line No."; Rec."Journal Line No.") { ApplicationArea = All; }
                field("Expected Entry Type"; Rec."Expected Entry Type") { ApplicationArea = All; }
                field("Expected Item No."; Rec."Expected Item No.") { ApplicationArea = All; }
                field("Expected Variant Code"; Rec."Expected Variant Code") { ApplicationArea = All; }
                field("Expected Location Code"; Rec."Expected Location Code") { ApplicationArea = All; }
                field("Expected Quantity"; Rec."Expected Quantity") { ApplicationArea = All; }
                field("Expected UoM"; Rec."Expected UoM") { ApplicationArea = All; }
                field("Expected Posting Date"; Rec."Expected Posting Date") { ApplicationArea = All; }
                field("Reconciliation Status"; Rec."Reconciliation Status") { ApplicationArea = All; }
                field("Reconciliation Details"; Rec."Reconciliation Details") { ApplicationArea = All; }
                field("Reconciled At"; Rec."Reconciled At") { ApplicationArea = All; }
            }
        }
    }
}
