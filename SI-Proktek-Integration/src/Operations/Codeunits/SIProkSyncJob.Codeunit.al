codeunit 57212 "SI Prok Sync Job"
{
    TableNo = "Job Queue Entry";

    // Minimal scheduler adapter. No separate sync engine, API request builder,
    // response parser, state machine, lease, or posting logic.
    // This is the same entry point used by "Отримати факти (Normal)".
    trigger OnRun()
    var
        Connection: Record "SI Prok Connection";
        Setup: Record "SI Prok Operations Setup";
        CaptureMgt: Codeunit "SI Prok Capture Mgt.";
        ConnectionCode: Code[50];
        DateFrom: Date;
        DateTo: Date;
        Imported: Integer;
        Existing: Integer;
        Conflicts: Integer;
        Failed: Integer;
    begin
        if Rec."Parameter String" = '' then
            Error('Job Queue Proktek: Parameter String має містити Connection Code.');
        if StrLen(Rec."Parameter String") > MaxStrLen(ConnectionCode) then
            Error('Job Queue Proktek: Connection Code задовгий.');

        ConnectionCode := CopyStr(Rec."Parameter String", 1, MaxStrLen(ConnectionCode));
        Connection.Get(ConnectionCode);
        if not Connection.Active then
            Error('Job Queue Proktek: профіль %1 неактивний.', ConnectionCode);
        if not Setup.Get(ConnectionCode) then
            Error('Job Queue Proktek: відсутні Operations Setup для %1.', ConnectionCode);
        if not Setup."Sync Enabled" then
            exit;

        DateTo := Today;
        DateFrom := DateTo - Setup."Sync Lookback Days";

        CaptureMgt.CaptureWithMode(
            DateFrom, DateTo, ConnectionCode,
            Enum::"SI Prok Capture Mode"::Normal,
            Imported, Existing, Conflicts, Failed);

        // Capture writes individual results/errors to the existing Raw API archive.
        // No additional processing, journal posting, or API calls are introduced.
    end;
}
