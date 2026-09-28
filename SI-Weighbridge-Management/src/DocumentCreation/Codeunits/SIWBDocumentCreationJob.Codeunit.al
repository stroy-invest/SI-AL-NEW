codeunit 59055 "SI WB Document Creation Job"
{
    trigger OnRun()
    begin
        RecoverStaleProcessingEntries();
        EnsureQueueForEligibleWeighings(DefaultEnqueueBatchSize());
        ProcessQueue(DefaultProcessingBatchSize());
    end;

    procedure RunOnce(
        MaxNewQueueItems: Integer;
        MaxQueueItems: Integer): Integer
    begin
        if MaxNewQueueItems <= 0 then
            Error('MaxNewQueueItems повинен бути більше 0.');

        if MaxQueueItems <= 0 then
            Error('MaxQueueItems повинен бути більше 0.');

        RecoverStaleProcessingEntries();
        EnsureQueueForEligibleWeighings(MaxNewQueueItems);
        exit(ProcessQueue(MaxQueueItems));
    end;

    procedure EnsureQueueForEligibleWeighings(
        MaxNewQueueItems: Integer): Integer
    var
        WeighingRecord: Record "SI Weighing Record";
        QueueEntry: Record "SI WB Document Creation Queue";
        InboundEvent: Record "SI EDS Inbound Event";
        WeighbridgeDocument: Record "SI Weighbridge Document";
        CreatedCount: Integer;
    begin
        if MaxNewQueueItems <= 0 then
            Error('MaxNewQueueItems повинен бути більше 0.');

        WeighingRecord.Reset();
        WeighingRecord.SetCurrentKey("Entry No.");
        WeighingRecord.SetRange(
            "Source Event Type",
            CompletedEventType());

        if not WeighingRecord.FindSet() then
            exit(0);

        repeat
            if not QueueEntryExists(
                WeighingRecord."Entry No.")
            then
                if InboundEvent.Get(
                    WeighingRecord."Inbound Entry No.")
                then
                    if (InboundEvent.Status =
                        InboundEvent.Status::Processed) and
                       (InboundEvent."Event Type" =
                        CompletedEventType())
                    then begin
                        // IMPORTANT: Init() does not clear the primary key value
                        // left in a reused Record variable. Clear() guarantees that
                        // AutoIncrement allocates a fresh Entry No. for every item.
                        Clear(QueueEntry);
                        QueueEntry.Init();
                        QueueEntry."Weighing Entry No." :=
                            WeighingRecord."Entry No.";
                        QueueEntry."Inbound Entry No." :=
                            WeighingRecord."Inbound Entry No.";

                        if FindDocumentForWeighing(
                            WeighingRecord."Entry No.",
                            WeighbridgeDocument)
                        then begin
                            QueueEntry.Status :=
                                "SI WB Doc Creation Status"::Completed;
                            QueueEntry."Completed At" :=
                                CurrentDateTime();
                            QueueEntry."Document Entry No." :=
                                WeighbridgeDocument."Entry No.";
                            QueueEntry."Document No." :=
                                WeighbridgeDocument."Document No.";
                        end else
                            QueueEntry.Status :=
                                "SI WB Doc Creation Status"::Pending;

                        // Use the Boolean return value so a concurrent/duplicate
                        // insert does not terminate the Job Queue session.
                        // The unique key on Weighing Entry No. remains the final
                        // database-level idempotency guard.
                        if QueueEntry.Insert(true) then
                            CreatedCount += 1;
                    end;

            if CreatedCount >= MaxNewQueueItems then
                break;
        until WeighingRecord.Next() = 0;

        exit(CreatedCount);
    end;

    procedure ProcessQueue(
        MaxQueueItems: Integer): Integer
    var
        QueueEntry: Record "SI WB Document Creation Queue";
        ProcessedCount: Integer;
    begin
        if MaxQueueItems <= 0 then
            Error('MaxQueueItems повинен бути більше 0.');

        while ProcessedCount < MaxQueueItems do begin
            if not FindNextEligibleQueueEntry(QueueEntry) then
                break;

            ProcessSingleQueueEntry(
                QueueEntry."Entry No.");

            ProcessedCount += 1;
        end;

        exit(ProcessedCount);
    end;

    procedure ProcessSingleQueueEntry(
        QueueEntryNo: BigInteger)
    var
        QueueEntry: Record "SI WB Document Creation Queue";
        WeighbridgeDocument: Record "SI Weighbridge Document";
        WorkerSucceeded: Boolean;
        ErrorText: Text;
    begin
        QueueEntry.LockTable();

        // The record can theoretically disappear between selection and
        // processing (for example during administrative cleanup). This is not
        // a reason to fail the whole recurring Job Queue entry.
        if not QueueEntry.Get(QueueEntryNo) then
            exit;

        if QueueEntry.Status =
           "SI WB Doc Creation Status"::Completed
        then
            exit;

        if QueueEntry.Status =
           "SI WB Doc Creation Status"::Processing
        then
            exit;

        if not IsEligibleForAttempt(QueueEntry) then
            exit;

        if FindDocumentForWeighing(
            QueueEntry."Weighing Entry No.",
            WeighbridgeDocument)
        then begin
            MarkCompleted(
                QueueEntry."Entry No.",
                WeighbridgeDocument);
            exit;
        end;

        QueueEntry.Status :=
            "SI WB Doc Creation Status"::Processing;
        QueueEntry."Attempt Count" += 1;
        QueueEntry."Last Attempt At" :=
            CurrentDateTime();
        QueueEntry."Completed At" := 0DT;
        QueueEntry.SetLastError('');
        QueueEntry.Modify(true);

        Commit();

        QueueEntry.Get(QueueEntryNo);

        ClearLastError();
        WorkerSucceeded :=
            Codeunit.Run(
                Codeunit::"SI WB Document Creator",
                QueueEntry);

        if WorkerSucceeded then
            exit;

        ErrorText := GetLastErrorText();
        MarkError(QueueEntryNo, ErrorText);
    end;

    local procedure FindNextEligibleQueueEntry(
        var QueueEntry: Record "SI WB Document Creation Queue"): Boolean
    var
        RetryBefore: DateTime;
    begin
        QueueEntry.Reset();
        QueueEntry.SetCurrentKey(Status, "Created At");
        QueueEntry.SetRange(
            Status,
            "SI WB Doc Creation Status"::Pending);

        if QueueEntry.FindFirst() then
            exit(true);

        RetryBefore :=
            CurrentDateTime() - RetryDelay();

        QueueEntry.Reset();
        QueueEntry.SetCurrentKey(Status, "Created At");
        QueueEntry.SetRange(
            Status,
            "SI WB Doc Creation Status"::Error);
        QueueEntry.SetFilter(
            "Attempt Count",
            '<%1',
            MaxAutomaticAttempts());
        QueueEntry.SetFilter(
            "Last Attempt At",
            '..%1',
            RetryBefore);

        exit(QueueEntry.FindFirst());
    end;

    local procedure IsEligibleForAttempt(
        QueueEntry: Record "SI WB Document Creation Queue"): Boolean
    begin
        case QueueEntry.Status of
            "SI WB Doc Creation Status"::Pending:
                exit(true);

            "SI WB Doc Creation Status"::Error:
                exit(
                    (QueueEntry."Attempt Count" <
                     MaxAutomaticAttempts()) and
                    (QueueEntry."Last Attempt At" <=
                     CurrentDateTime() - RetryDelay()));
        end;

        exit(false);
    end;

    local procedure QueueEntryExists(
        WeighingEntryNo: BigInteger): Boolean
    var
        QueueEntry: Record "SI WB Document Creation Queue";
    begin
        exit(QueueEntry.FindByWeighing(WeighingEntryNo));
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
                'Невідома помилка автоматичного створення операційного документа.';

        QueueEntry.SetLastError(ErrorText);
        QueueEntry.Modify(true);
    end;

    local procedure RecoverStaleProcessingEntries()
    var
        QueueEntry: Record "SI WB Document Creation Queue";
        StaleBefore: DateTime;
    begin
        StaleBefore :=
            CurrentDateTime() - ProcessingStaleAfter();

        QueueEntry.Reset();
        QueueEntry.SetCurrentKey(Status, "Created At");
        QueueEntry.SetRange(
            Status,
            "SI WB Doc Creation Status"::Processing);
        QueueEntry.SetFilter(
            "Last Attempt At",
            '..%1',
            StaleBefore);

        if not QueueEntry.FindSet(true) then
            exit;

        repeat
            QueueEntry.Status :=
                "SI WB Doc Creation Status"::Error;
            QueueEntry.SetLastError(
                'Попередню спробу створення документа було перервано або вона не завершилась у допустимий час. Запис повернено до retry-циклу.');
            QueueEntry.Modify(true);
        until QueueEntry.Next() = 0;
    end;

    local procedure DefaultEnqueueBatchSize(): Integer
    begin
        exit(100);
    end;

    local procedure DefaultProcessingBatchSize(): Integer
    begin
        exit(100);
    end;

    local procedure MaxAutomaticAttempts(): Integer
    begin
        exit(3);
    end;

    local procedure RetryDelay(): Duration
    begin
        exit(60000);
    end;

    local procedure ProcessingStaleAfter(): Duration
    begin
        exit(300000);
    end;

    local procedure CompletedEventType(): Code[50]
    begin
        exit('WEIGHING_COMPLETED');
    end;
}
