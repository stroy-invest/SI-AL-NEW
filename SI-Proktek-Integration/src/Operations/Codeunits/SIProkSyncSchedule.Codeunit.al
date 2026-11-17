codeunit 57213 "SI Prok Sync Schedule"
{
    Permissions = tabledata "Job Queue Entry" = RIMD;

    procedure Apply(ConnectionCode: Code[50])
    var
        Config: Codeunit "SI Prok Operations Config";
        Setup: Record "SI Prok Operations Setup";
        Job: Record "Job Queue Entry";
        Connection: Record "SI Prok Connection";
    begin
        Config.Resolve(ConnectionCode, Setup);
        Connection.Get(ConnectionCode);
        if not Connection.Active then
            Error('Job Queue можна налаштувати лише для активного профілю Proktek: %1.', ConnectionCode);
        if not Setup."Sync Enabled" then
            Error('Спочатку увімкніть «Автоматична синхронізація дозволена» для %1.', ConnectionCode);

        Job.SetRange("Object Type to Run", Job."Object Type to Run"::Codeunit);
        Job.SetRange("Object ID to Run", Codeunit::"SI Prok Sync Job");
        Job.SetRange("Parameter String", ConnectionCode);
        if Job.FindFirst() then begin
            if Job.Next() <> 0 then
                Error('Для профілю %1 знайдено декілька Job Queue Entries. Усуньте дублікати.', ConnectionCode);
            Job.FindFirst();
            if Job."No. of Minutes between Runs" = Setup."Sync Interval Minutes" then
                exit;
            if Job.Status <> Job.Status::"On Hold" then
                Error('Щоб змінити інтервал, переведіть Job Queue Entry %1 у стан On Hold, а потім повторіть дію.', Job.ID);
            Job.Validate("No. of Minutes between Runs", Setup."Sync Interval Minutes");
            Job.Modify(true);
            exit;
        end;

        Job.Init();
        Job."Object Type to Run" := Job."Object Type to Run"::Codeunit;
        Job."Object ID to Run" := Codeunit::"SI Prok Sync Job";
        Job."Parameter String" := ConnectionCode;
        Job.Description := CopyStr(StrSubstNo('SI Proktek Sync / %1', ConnectionCode), 1, MaxStrLen(Job.Description));
        Job."Recurring Job" := true;
        Job."No. of Minutes between Runs" := Setup."Sync Interval Minutes";
        Job."Run on Mondays" := true;
        Job."Run on Tuesdays" := true;
        Job."Run on Wednesdays" := true;
        Job."Run on Thursdays" := true;
        Job."Run on Fridays" := true;
        Job."Run on Saturdays" := true;
        Job."Run on Sundays" := true;
        Job."Maximum No. of Attempts to Run" := 1;
        if not Codeunit.Run(Codeunit::"Job Queue - Enqueue", Job) then
            Error('Не вдалося створити Job Queue для %1: %2', ConnectionCode, GetLastErrorText());
    end;
}
