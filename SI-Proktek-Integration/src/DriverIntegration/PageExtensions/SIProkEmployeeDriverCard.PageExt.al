pageextension 57146 "SI Prok Employee Driver Card" extends "Employee Card"
{
    layout
    {
        addlast(General)
        {
            field("SI Is Driver"; Rec."SI Is Driver") { ApplicationArea = All; }
            field("SI Driver Tax ID"; Rec."SI Driver Tax ID") { ApplicationArea = All; }
        }
    }
}
