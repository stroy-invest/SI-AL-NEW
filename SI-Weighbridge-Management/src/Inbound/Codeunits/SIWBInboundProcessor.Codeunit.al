codeunit 59050 "SI WB Inbound Processor"
{
    procedure ProcessAllAcceptedEvents(
        MaxEvents: Integer): Integer
    var
        InboundEvent: Record "SI EDS Inbound Event";
        AttemptedCount: Integer;
    begin
        if MaxEvents <= 0 then
            Error('MaxEvents повинен бути більше 0.');

        while AttemptedCount < MaxEvents do begin
            InboundEvent.Reset();

            InboundEvent.SetCurrentKey(
                Status,
                "Received At");

            InboundEvent.SetRange(
                Status,
                InboundEvent.Status::Accepted);

            // Phase I:
            // only final weighings are materialized into SI Weighing Record.
            //
            // FIRST_WEIGHING_RECORDED deliberately remains untouched
            // in the raw EDS inbound store.
            InboundEvent.SetRange(
                "Event Type",
                CompletedEventType());

            if not InboundEvent.FindFirst() then
                break;

            ProcessSingleEvent(
                InboundEvent."Entry No.");

            AttemptedCount += 1;
        end;

        exit(AttemptedCount);
    end;

    procedure ProcessAcceptedEvents(
        ServiceCode: Code[50];
        MaxEvents: Integer): Integer
    var
        InboundEvent: Record "SI EDS Inbound Event";
        AttemptedCount: Integer;
    begin
        if ServiceCode = '' then
            Error('Service Code не задано.');

        if MaxEvents <= 0 then
            Error('MaxEvents повинен бути більше 0.');

        while AttemptedCount < MaxEvents do begin
            InboundEvent.Reset();

            InboundEvent.SetCurrentKey(
                Status,
                "Received At");

            InboundEvent.SetRange(
                "Service Code",
                ServiceCode);

            InboundEvent.SetRange(
                Status,
                InboundEvent.Status::Accepted);

            InboundEvent.SetRange(
                "Event Type",
                CompletedEventType());

            if not InboundEvent.FindFirst() then
                break;

            ProcessSingleEvent(
                InboundEvent."Entry No.");

            AttemptedCount += 1;
        end;

        exit(AttemptedCount);
    end;

    procedure ProcessSingleEvent(
        InboundEntryNo: BigInteger)
    var
        InboundEvent: Record "SI EDS Inbound Event";
        WorkerSucceeded: Boolean;
        ErrorText: Text;
    begin
        // ------------------------------------------------------------
        // Claim event
        //
        // Locking protects the status transition when a Job Queue
        // session and an administrator happen to process the same
        // event at almost the same time.
        // ------------------------------------------------------------

        InboundEvent.LockTable();

        if not InboundEvent.Get(
            InboundEntryNo)
        then
            Error(
                'EDS inbound event %1 не знайдено.',
                InboundEntryNo);

        // Idempotent no-op.
        if InboundEvent.Status =
           InboundEvent.Status::Processed
        then
            exit;

        // Another processor has already claimed the event.
        // Do not turn this normal concurrency situation into an error.
        if InboundEvent.Status =
           InboundEvent.Status::Processing
        then
            exit;

        if InboundEvent.Status <>
           InboundEvent.Status::Accepted
        then
            Error(
                'EDS inbound event %1 має статус %2. Очікувався статус Accepted.',
                InboundEntryNo,
                Format(InboundEvent.Status));

        if InboundEvent."Event Type" <>
           CompletedEventType()
        then
            Error(
                'EDS inbound event %1 має непідтримуваний тип %2. Обробляються лише події WEIGHING_COMPLETED.',
                InboundEntryNo,
                InboundEvent."Event Type");

        InboundEvent.Status :=
            InboundEvent.Status::Processing;

        InboundEvent."Processing Started At" :=
            CurrentDateTime();

        InboundEvent."Processed At" :=
            0DT;

        InboundEvent."Processing Attempt Count" += 1;

        InboundEvent.SetLastError('');

        InboundEvent.Modify(true);

        // Codeunit.Run(Boolean) must start at a clean
        // transaction boundary so one bad event cannot
        // roll back the whole batch.
        Commit();

        // ------------------------------------------------------------
        // Domain worker
        // ------------------------------------------------------------

        ClearLastError();

        WorkerSucceeded :=
            Codeunit.Run(
                Codeunit::"SI WB Inbound Worker",
                InboundEvent);

        if WorkerSucceeded then
            exit;

        ErrorText :=
            GetLastErrorText();

        MarkAsError(
            InboundEntryNo,
            ErrorText);
    end;

    procedure RetrySingleEvent(
        InboundEntryNo: BigInteger)
    var
        InboundEvent: Record "SI EDS Inbound Event";
    begin
        InboundEvent.LockTable();

        if not InboundEvent.Get(
            InboundEntryNo)
        then
            Error(
                'EDS inbound event %1 не знайдено.',
                InboundEntryNo);

        if InboundEvent.Status <>
           InboundEvent.Status::Error
        then
            Error(
                'Повторно обробити можна лише подію зі статусом Error. Поточний статус: %1.',
                Format(InboundEvent.Status));

        if InboundEvent."Event Type" <>
           CompletedEventType()
        then
            Error(
                'EDS inbound event %1 має непідтримуваний тип %2. Обробляються лише події WEIGHING_COMPLETED.',
                InboundEntryNo,
                InboundEvent."Event Type");

        // Return failed event into the normal Accepted path.
        //
        // Processing Attempt Count is deliberately NOT reset.
        // It remains the complete audit history of attempts.

        InboundEvent.Status :=
            InboundEvent.Status::Accepted;

        InboundEvent."Processing Started At" :=
            0DT;

        InboundEvent."Processed At" :=
            0DT;

        InboundEvent.SetLastError('');

        InboundEvent.Modify(true);

        Commit();

        ProcessSingleEvent(
            InboundEntryNo);
    end;

    procedure CompletedEventType(): Code[50]
    begin
        exit('WEIGHING_COMPLETED');
    end;

    local procedure MarkAsError(
        InboundEntryNo: BigInteger;
        ErrorText: Text)
    var
        InboundEvent: Record "SI EDS Inbound Event";
    begin
        if not InboundEvent.Get(
            InboundEntryNo)
        then
            exit;

        InboundEvent.Status :=
            InboundEvent.Status::Error;

        InboundEvent."Processed At" :=
            CurrentDateTime();

        if ErrorText = '' then
            ErrorText :=
                'Невідома помилка обробки inbound event.';

        InboundEvent.SetLastError(
            ErrorText);

        InboundEvent.Modify(true);

        Commit();
    end;
}