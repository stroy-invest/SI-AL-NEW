pageextension 53025 "SI Item Variants Semantic" extends "SI Item Variants Part"
{
    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("SI Configuration No.", "SI Item Configuration No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("SI Configuration No.", "SI Item Configuration No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("SI Configuration No.", "SI Item Configuration No.");
    end;
}
