codeunit 57103 "SI Prok Fact Intake Worker"
{
    TableNo = "SI Prok Raw API Response";

    trigger OnRun()
    var
        Fact: Record "SI Prok Production Fact";
        FactMgt: Codeunit "SI Prok Prod Fact Mgt.";
        Reason: Text;
    begin
        // Run's Boolean return gives this detail its own rollback boundary.
        // Caller must commit the raw archive before invoking this worker.
        Rec."Intake Result" := FactMgt.PersistIntake(
            CanonicalText, Rec."Connection Code", Rec."Capture Mode", Fact, Reason);
        Rec."Production Fact Entry No." := Fact."Entry No.";
        // Keep full current Config in its own primary-response archive row.
        // Previous projection remains in Fact.Canonical JSON; neither is overwritten.
        Rec."Error Message" := CopyStr(
            StrSubstNo('Material Config Raw Entry No.=%1; Previous/Accepted Fact Entry No.=%2; Details Raw Entry No.=%3. %4',
                ConfigurationArchiveEntryNo, Fact."Entry No.", Rec."Entry No.", Reason),
            1, MaxStrLen(Rec."Error Message"));
        Rec."Processing Status" := Rec."Processing Status"::Processed;
        if Rec."Intake Result" = Rec."Intake Result"::Conflict then
            Rec."Processing Status" := Rec."Processing Status"::Error;
        Rec.Modify(true);
    end;

    procedure SetCanonical(Value: Text)
    begin
        CanonicalText := Value;
    end;

    procedure SetConfigurationArchive(EntryNo: Integer)
    begin
        ConfigurationArchiveEntryNo := EntryNo;
    end;

    var
        CanonicalText: Text;
        ConfigurationArchiveEntryNo: Integer;
}
