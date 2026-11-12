page 57092 "SI Prok Prod Fact Materials"
{
    PageType = ListPart;
    SourceTable = "SI Prok Prod Fact Material";
    Caption = 'Матеріали';
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
                field("Material Name"; Rec."Material Name") { ApplicationArea = All; Caption = 'Матеріал'; }
                field("BC Base UoM"; Rec."BC Base UoM") { ApplicationArea = All; Caption = 'Од. виміру'; }
                field("Requested Kg"; Rec."Requested Kg") { ApplicationArea = All; Caption = 'План, кг'; }
                field("Actual Kg"; Rec."Actual Kg") { ApplicationArea = All; Caption = 'Факт, кг'; }
                field("Variance Kg"; Rec."Variance Kg") { ApplicationArea = All; Caption = 'Відхилення, кг'; }
            }
        }
    }
}
