pageextension 53026 "SI Group Items Semantic" extends "SI Group Items Part"
{
    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("SI Configuration No.");
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("SI Configuration No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("SI Configuration No.");
    end;
}
