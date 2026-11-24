codeunit 57991 "SI Prok Recovery Worker"
{
    TableNo = "SI Prok Raw API Response";
    trigger OnRun()
    var
        Fact: Record "SI Prok Production Fact";
        Mgt: Codeunit "SI Prok Prod Fact Mgt.";
        Result: Enum "SI Prok Intake Result";
        Issue: Text;
        Recovery: Codeunit "SI Prok Fact Recovery";
    begin
        Result := Mgt.PersistIntake(Canonical, Rec."Connection Code", Rec."Capture Mode", Fact, Issue);
        if Result = Result::Conflict then
            Error('%1', Issue);
        Recovery.Apply(Fact, RequestNo, Reason, Rec."Entry No.");
        Rec."Production Fact Entry No." := Fact."Entry No.";
        Rec."Intake Result" := Result;
        Rec."Processing Status" := Rec."Processing Status"::Processed;
        Rec.Modify(true);
    end;
    procedure Setup(Value: Text; ReqNo: Integer; Why: Text[250])
    begin
        Canonical := Value;
        RequestNo := ReqNo;
        Reason := Why;
    end;
    var
        Canonical: Text;
        RequestNo: Integer;
        Reason: Text[250];
}
