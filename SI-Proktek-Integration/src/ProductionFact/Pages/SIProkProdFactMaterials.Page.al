page 57092 "SI Prok Prod Fact Materials"
{
    PageType = ListPart;
    SourceTable = "SI Prok Prod Fact Material";
    Caption = 'Матеріали';
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("External Material Code"; Rec."External Material Code") { ApplicationArea = All; Visible = false; }
                field("Material UUID"; Rec."Material UUID") { ApplicationArea = All; Visible = false; }
                field("BC Material Resolved"; Rec."BC Material Resolved") { ApplicationArea = All; Visible = false; }
                field("Actual Observed Slot Count"; Rec."Actual Observed Slot Count") { ApplicationArea = All; Visible = false; }
                field("Source Slot Count"; Rec."Source Slot Count") { ApplicationArea = All; Visible = false; }
                field("Material Name"; Rec."Material Name") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field("Variant Code"; Rec."Variant Code") { ApplicationArea = All; }
                field("Requested Kg"; Rec."Requested Kg") { ApplicationArea = All; }
                field("Adjusted Kg"; Rec."Adjusted Kg") { ApplicationArea = All; }
                field("Actual Kg"; Rec."Actual Kg") { ApplicationArea = All; }
                field("Variance Kg"; Rec."Variance Kg") { ApplicationArea = All; }
                field("Variance %"; Rec."Variance %") { ApplicationArea = All; }
                field("BC Base UoM"; Rec."BC Base UoM") { ApplicationArea = All; }
                field("Requested Base Qty"; Rec."Requested Base Qty") { ApplicationArea = All; Visible = false; }
                field("Adjusted Base Qty"; Rec."Adjusted Base Qty") { ApplicationArea = All; Visible = false; }
                field("Actual Base Qty"; Rec."Actual Base Qty") { ApplicationArea = All; }
                field("Variance Base Qty"; Rec."Variance Base Qty") { ApplicationArea = All; Visible = false; }
                field("UoM Normalized"; Rec."UoM Normalized") { ApplicationArea = All; }
                field("UoM Diagnostic"; Rec."UoM Diagnostic") { ApplicationArea = All; Visible = false; }

            }
        }
    }
}
