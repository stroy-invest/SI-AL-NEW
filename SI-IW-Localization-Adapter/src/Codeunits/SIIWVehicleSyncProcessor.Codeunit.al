codeunit 65005 "SI IW Vehicle Sync Processor"
{
    // Job Queue entry point. Can also be invoked manually for diagnostics.
    trigger OnRun()
    begin
        ProcessDue();
    end;

    procedure ProcessDue()
    var
        Outbox: Record "SI IW Vehicle Sync Outbox";
        Candidate: Record "SI IW Vehicle Sync Outbox";
        VehicleNos: List of [Code[20]];
        VehicleNo: Code[20];
    begin
        // Snapshot candidate identities before processing; processing changes Status.
        Outbox.SetRange(Status, Outbox.Status::Pending);
        Outbox.SetFilter("Next Attempt At", '<=%1', CurrentDateTime());
        if Outbox.FindSet() then
            repeat
                VehicleNos.Add(Outbox."Vehicle No.");
            until Outbox.Next() = 0;

        foreach VehicleNo in VehicleNos do begin
            if Candidate.Get(VehicleNo) then
                if (Candidate.Status = Candidate.Status::Pending) and
                   (Candidate."Next Attempt At" <= CurrentDateTime()) then
                    ProcessOne(Candidate);
        end;
    end;

    local procedure ProcessOne(var Candidate: Record "SI IW Vehicle Sync Outbox")
    var
        Worker: Codeunit "SI IW Vehicle Sync Worker";
        Outbox: Record "SI IW Vehicle Sync Outbox";
        ErrorText: Text;
        DelayMinutes: Integer;
    begin
        // Codeunit.Run(Boolean) isolates all worker writes in its own transaction.
        // No writes/COMMIT are performed in this caller before the invocation.
        ClearLastError();
        if Worker.Run(Candidate) then
            exit;

        ErrorText := GetLastErrorText();
        Outbox.LockTable();
        if not Outbox.Get(Candidate."Vehicle No.") then
            exit;
        if Outbox."Revision No." <> Candidate."Revision No." then
            exit; // A new request supersedes the failed attempt.
        if Outbox.Status <> Outbox.Status::Pending then
            exit;

        Outbox."Attempt Count" += 1;
        Outbox."Last Attempt At" := CurrentDateTime();
        Outbox."Last Error" := CopyStr(ErrorText, 1, MaxStrLen(Outbox."Last Error"));
        Outbox."Modified At" := CurrentDateTime();
        if Outbox."Attempt Count" >= 3 then begin
            Outbox.Status := Outbox.Status::Failed;
            Clear(Outbox."Next Attempt At");
        end else begin
            if Outbox."Attempt Count" = 1 then
                DelayMinutes := 1
            else
                DelayMinutes := 5;
            Outbox."Next Attempt At" := CurrentDateTime() + DelayMinutes * 60000;
        end;
        Outbox.Modify(true);
        Commit(); // Persist failure before processing the next vehicle.
    end;
}
