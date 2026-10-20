codeunit 70056 "SI Audit Batch Reset"
{
    // Lab-only reset. No HTTP, no writes to production SI Business Partner.
    procedure ResetBatch(BatchNo: Code[20])
    var
        Batch: Record "SI Audit Batch";
        Entry: Record "SI Audit Entry";
        Log: Record "SI Audit Request Log";
        Result: Record "SI Audit Registry Result";
        BP: Record "SI Audit BP";
        Addr: Record "SI Audit BP Address";
        Job: Record "Job Queue Entry";
        BPNo: Code[60];
        EntryCount: Integer;
        LogCount: Integer;
        ResetCount: Integer;
        SkipCount: Integer;
    begin
        Batch.LockTable();
        Batch.Get(BatchNo);
        if Batch.Status = Batch.Status::Running then
            Error('Пакет %1 виконується. Спочатку зупиніть виконання.', BatchNo);

        // Prevent a scheduled worker from starting during the cleanup.
        Job.SetRange("Object Type to Run", Job."Object Type to Run"::Codeunit);
        Job.SetRange("Object ID to Run", 70055);
        Job.SetFilter(Status, '%1|%2', Job.Status::Ready, Job.Status::"In Process");
        if Job.FindSet() then
            repeat
                if Job."Parameter String" = BatchNo then
                    Error('Job Queue для %1 активний. Переведіть завдання 70055 у стан На утриманні (On Hold) перед очищенням.', BatchNo);
            until Job.Next() = 0;

        Entry.SetRange("Batch No.", BatchNo);
        EntryCount := Entry.Count();
        Log.SetRange("Batch No.", BatchNo);
        LogCount := Log.Count();
        if not Confirm('СКИНУТИ результати пакета %1? Записів 1С: %2; HTTP-журналів: %3. Вихідні дані 1С залишаться. Дію не можна скасувати.', false, BatchNo, EntryCount, LogCount) then
            exit;

        // Registry results are keyed by HTTP log entry number, not batch number.
        if Log.FindSet() then
            repeat
                if Result.Get(Log."Entry No.") then
                    Result.Delete(true);
            until Log.Next() = 0;

        // Delete only synthetic BP records belonging to this batch.
        if Entry.FindSet(true) then
            repeat
                BPNo := CopyStr(StrSubstNo('%1-%2', Entry."Batch No.", Entry."Entry No."), 1, MaxStrLen(BPNo));
                if Entry."Audit BP No." <> '' then
                    BPNo := Entry."Audit BP No.";
                // Do not touch unrelated BP references, even in the lab.
                if BPNo = CopyStr(StrSubstNo('%1-%2', BatchNo, Entry."Entry No."), 1, MaxStrLen(BPNo)) then begin
                    Addr.Reset();
                    Addr.SetRange("Business Partner No.", BPNo);
                    Addr.DeleteAll(true);
                    if BP.Get(BPNo) then
                        BP.Delete(true);
                end;

                // Keep all imported source columns intact.
                Entry."Audit BP No." := '';
                Entry."Registry Full Name" := '';
                Entry."Full Name 1C" := '';
                Entry."Normalized Name 1C" := '';
                Entry."Normalized Registry Name" := '';
                Entry."Last Checked At" := 0DT;
                Entry."Attempt Count" := 0;
                Entry."Next Attempt At" := 0DT;
                if Entry."Is FOP" or (Entry."Result Code" = 'SOURCE_SKIPPED') then begin
                    Entry."Processing Status" := Entry."Processing Status"::Skipped;
                    Entry."Result Code" := 'SOURCE_SKIPPED';
                    if Entry."Result Details" = '' then
                        Entry."Result Details" := 'Виключено під час імпорту 1С';
                    SkipCount += 1;
                end else begin
                    Entry."Processing Status" := Entry."Processing Status"::Pending;
                    Entry."Result Code" := '';
                    Entry."Result Details" := '';
                    ResetCount += 1;
                end;
                Entry.Modify(true);
            until Entry.Next() = 0;

        Log.DeleteAll(true); // Deletes raw HTTP BLOBs along with lab log records.
        Batch.Status := Batch.Status::Ready;
        Batch.Modify(true);

        // Single transaction; no COMMIT. All-or-nothing cleanup.
        Message('Пакет %1 очищено. Очікують GET: %2; пропущено: %3; видалено HTTP-журналів: %4.',
            BatchNo, ResetCount, SkipCount, LogCount);
    end;
}
