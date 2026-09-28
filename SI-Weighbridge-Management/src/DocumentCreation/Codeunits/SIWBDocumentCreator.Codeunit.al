codeunit 59056 "SI WB Document Creator"
{
    TableNo = "SI WB Document Creation Queue";

    trigger OnRun()
    begin
        ProcessQueueEntry(Rec);
    end;

    procedure CreateManuallyAndOpen(
        WeighingRecord: Record "SI Weighing Record")
    var
        QueueEntry: Record "SI WB Document Creation Queue";
        WeighbridgeDocument: Record "SI Weighbridge Document";
        WorkerSucceeded: Boolean;
        ErrorText: Text;
    begin
        ValidateEligibleWeighing(WeighingRecord);
        EnsureQueueEntry(WeighingRecord, QueueEntry);

        if FindDocumentForWeighing(
            WeighingRecord."Entry No.",
            WeighbridgeDocument)
        then begin
            MarkCompleted(
                QueueEntry."Entry No.",
                WeighbridgeDocument);

            Page.Run(
                Page::"SI Weighbridge Document Card",
                WeighbridgeDocument);
            exit;
        end;

        ClaimForManualProcessing(QueueEntry."Entry No.");
        Commit();

        QueueEntry.Get(QueueEntry."Entry No.");

        ClearLastError();
        WorkerSucceeded :=
            Codeunit.Run(
                Codeunit::"SI WB Document Creator",
                QueueEntry);

        if not WorkerSucceeded then begin
            ErrorText := GetLastErrorText();
            MarkError(QueueEntry."Entry No.", ErrorText);
            Commit();

            if ErrorText = '' then
                ErrorText := 'Невідома помилка створення операційного документа.';

            Error('%1', ErrorText);
        end;

        if not FindDocumentForWeighing(
            WeighingRecord."Entry No.",
            WeighbridgeDocument)
        then
            Error(
                'Для зважування %1 операційний документ не знайдено після успішного створення.',
                WeighingRecord."Entry No.");

        Page.Run(
            Page::"SI Weighbridge Document Card",
            WeighbridgeDocument);
    end;

    local procedure ProcessQueueEntry(
        var QueueEntry: Record "SI WB Document Creation Queue")
    var
        WeighingRecord: Record "SI Weighing Record";
        WeighbridgeDocument: Record "SI Weighbridge Document";
        DocumentMgt: Codeunit "SI WB Document Mgt.";
    begin
        if QueueEntry.Status <>
           "SI WB Doc Creation Status"::Processing
        then
            Error(
                'Запис черги %1 має статус %2. Очікувався статус Processing.',
                QueueEntry."Entry No.",
                Format(QueueEntry.Status));

        if not WeighingRecord.Get(
            QueueEntry."Weighing Entry No.")
        then
            Error(
                'Зважування %1 не знайдено.',
                QueueEntry."Weighing Entry No.");

        ValidateEligibleWeighing(WeighingRecord);

        DocumentMgt.CreateFromWeighing(
            WeighingRecord,
            WeighbridgeDocument);

        MarkCompleted(
            QueueEntry."Entry No.",
            WeighbridgeDocument);
    end;

    local procedure ValidateEligibleWeighing(
        WeighingRecord: Record "SI Weighing Record")
    var
        InboundEvent: Record "SI EDS Inbound Event";
    begin
        WeighingRecord.TestField("Entry No.");

        if WeighingRecord."Source Event Type" <>
           CompletedEventType()
        then
            Error(
                'Зважування %1 створене не з WEIGHING_COMPLETED (%2). Операційний документ автоматично не створюється.',
                WeighingRecord."Entry No.",
                WeighingRecord."Source Event Type");

        if not InboundEvent.Get(
            WeighingRecord."Inbound Entry No.")
        then
            Error(
                'EDS inbound event %1 для зважування %2 не знайдено.',
                WeighingRecord."Inbound Entry No.",
                WeighingRecord."Entry No.");

        if InboundEvent."Event Type" <>
           CompletedEventType()
        then
            Error(
                'EDS inbound event %1 має тип %2. Очікувався WEIGHING_COMPLETED.',
                InboundEvent."Entry No.",
                InboundEvent."Event Type");

        if InboundEvent.Status <>
           InboundEvent.Status::Processed
        then
            Error(
                'EDS inbound event %1 має статус %2. Операційний документ створюється лише після успішного inbound processing.',
                InboundEvent."Entry No.",
                Format(InboundEvent.Status));
    end;

    local procedure EnsureQueueEntry(
        WeighingRecord: Record "SI Weighing Record";
        var QueueEntry: Record "SI WB Document Creation Queue")
    begin
        if QueueEntry.FindByWeighing(
            WeighingRecord."Entry No.")
        then
            exit;

        // Init() keeps the current primary-key value in a reused Record
        // variable. Clear() is required before an AutoIncrement insert.
        Clear(QueueEntry);
        QueueEntry.Init();
        QueueEntry."Weighing Entry No." :=
            WeighingRecord."Entry No.";
        QueueEntry."Inbound Entry No." :=
            WeighingRecord."Inbound Entry No.";
        QueueEntry.Status :=
            "SI WB Doc Creation Status"::Pending;

        // If another session has inserted the same weighing concurrently,
        // do not create a duplicate and do not fail the caller. Re-read the
        // existing queue item protected by the unique Weighing Entry No. key.
        if not QueueEntry.Insert(true) then
            QueueEntry.FindByWeighing(WeighingRecord."Entry No.");
    end;

    local procedure ClaimForManualProcessing(
        QueueEntryNo: BigInteger)
    var
        QueueEntry: Record "SI WB Document Creation Queue";
    begin
        QueueEntry.LockTable();

        if not QueueEntry.Get(QueueEntryNo) then
            Error(
                'Запис черги %1 не знайдено.',
                QueueEntryNo);

        if QueueEntry.Status =
           "SI WB Doc Creation Status"::Processing
        then
            Error(
                'Запис черги %1 уже обробляється іншим сеансом.',
                QueueEntryNo);

        QueueEntry.Status :=
            "SI WB Doc Creation Status"::Processing;
        QueueEntry."Attempt Count" += 1;
        QueueEntry."Last Attempt At" :=
            CurrentDateTime();
        QueueEntry."Completed At" := 0DT;
        QueueEntry.SetLastError('');
        QueueEntry.Modify(true);
    end;

    local procedure MarkCompleted(
        QueueEntryNo: BigInteger;
        WeighbridgeDocument: Record "SI Weighbridge Document")
    var
        QueueEntry: Record "SI WB Document Creation Queue";
    begin
        if not QueueEntry.Get(QueueEntryNo) then
            exit;

        QueueEntry.Status :=
            "SI WB Doc Creation Status"::Completed;
        QueueEntry."Completed At" :=
            CurrentDateTime();
        QueueEntry."Document Entry No." :=
            WeighbridgeDocument."Entry No.";
        QueueEntry."Document No." :=
            WeighbridgeDocument."Document No.";
        QueueEntry.SetLastError('');
        QueueEntry.Modify(true);
    end;

    local procedure MarkError(
        QueueEntryNo: BigInteger;
        ErrorText: Text)
    var
        QueueEntry: Record "SI WB Document Creation Queue";
    begin
        if not QueueEntry.Get(QueueEntryNo) then
            exit;

        QueueEntry.Status :=
            "SI WB Doc Creation Status"::Error;
        QueueEntry."Completed At" := 0DT;

        if ErrorText = '' then
            ErrorText :=
                'Невідома помилка створення операційного документа.';

        QueueEntry.SetLastError(ErrorText);
        QueueEntry.Modify(true);
    end;

    local procedure FindDocumentForWeighing(
        WeighingEntryNo: BigInteger;
        var WeighbridgeDocument: Record "SI Weighbridge Document"): Boolean
    begin
        WeighbridgeDocument.Reset();
        WeighbridgeDocument.SetRange(
            "Weighing Entry No.",
            WeighingEntryNo);
        exit(WeighbridgeDocument.FindFirst());
    end;

    local procedure CompletedEventType(): Code[50]
    begin
        exit('WEIGHING_COMPLETED');
    end;
}
