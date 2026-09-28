pageextension 59150 "SI EDS Inbound Events WB Ext" extends "SI EDS Inbound Events"
{
    layout
    {
        // Weighbridge-specific diagnostics deliberately live in the
        // Weighbridge application rather than in Foundation EDS.
        // Foundation therefore remains generic and does not need to know
        // anything about codeunit 59052 or WEIGHING_COMPLETED semantics.
        addlast(Content)
        {
            group(SIWBProcessingErrorPanel)
            {
                Caption = 'Діагностика обробки';
                Visible = ShowErrorPanel;

                field(SIWBErrorTitle; ErrorTitle)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                    Editable = false;
                    Style = Unfavorable;
                    ToolTip = 'Подія повного зважування завершила обробку з помилкою.';
                }

                field(SIWBErrorEntryNo; ErrorEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                    Editable = false;
                    ToolTip = 'Показує Entry No. вибраної inbound-події.';
                }

                field(SIWBErrorSourceRecordId; ErrorSourceRecordId)
                {
                    ApplicationArea = All;
                    Caption = 'Source Record ID';
                    Editable = false;
                    ToolTip = 'Показує ідентифікатор вихідного запису PromSoft.';
                }

                field(SIWBErrorAttemptCount; ErrorAttemptCount)
                {
                    ApplicationArea = All;
                    Caption = 'Спроб обробки';
                    Editable = false;
                    ToolTip = 'Показує кількість спроб downstream-обробки події.';
                }

                field(SIWBErrorProcessingStartedAt; ErrorProcessingStartedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Початок';
                    Editable = false;
                    ToolTip = 'Показує час початку останньої спроби обробки.';
                }

                field(SIWBErrorProcessedAt; ErrorProcessedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Завершено';
                    Editable = false;
                    ToolTip = 'Показує час завершення останньої спроби обробки.';
                }

                field(SIWBLastProcessingError; LastProcessingError)
                {
                    ApplicationArea = All;
                    Caption = 'Остання помилка';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Показує останню помилку downstream-обробки, збережену для вибраної події.';
                }

                field(SIWBErrorJobStatus; JobQueueStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'SI WB Inbound Job';
                    Editable = false;
                    ToolTip = 'Показує поточний статус Job Queue Entry для codeunit 59052 SI WB Inbound Job.';
                }

                field(SIWBErrorJobLink; JobQueueLinkText)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                    Editable = false;
                    DrillDown = true;
                    Style = StrongAccent;
                    ToolTip = 'Відкриває Job Queue Entries, відфільтровані за SI WB Inbound Job.';

                    trigger OnDrillDown()
                    begin
                        OpenInboundJobQueueEntry();
                    end;
                }
            }

            group(SIWBProcessingDelayPanel)
            {
                Caption = 'Контроль обробки';
                Visible = ShowDelayPanel;

                field(SIWBDelayTitle; DelayTitle)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                    Editable = false;
                    Style = Attention;
                    ToolTip = 'Подія повного зважування перебуває у статусі Accepted довше допустимого часу.';
                }

                field(SIWBDelaySummary; DelaySummary)
                {
                    ApplicationArea = All;
                    Caption = 'Стан';
                    Editable = false;
                    MultiLine = true;
                    Style = Attention;
                    ToolTip = 'Показує, скільки часу вибрана подія очікує downstream-обробки.';
                }

                field(SIWBPendingCompletedCount; PendingCompletedCount)
                {
                    ApplicationArea = All;
                    Caption = 'Очікує WEIGHING_COMPLETED';
                    Editable = false;
                    ToolTip = 'Показує кількість WEIGHBRIDGE / WEIGHING_COMPLETED подій у статусі Accepted.';
                }

                field(SIWBOldestPendingAt; OldestPendingAt)
                {
                    ApplicationArea = All;
                    Caption = 'Найстаріша Accepted';
                    Editable = false;
                    ToolTip = 'Показує час отримання найстарішої WEIGHBRIDGE / WEIGHING_COMPLETED події, що все ще має статус Accepted.';
                }

                field(SIWBDelayJobStatus; JobQueueStatusText)
                {
                    ApplicationArea = All;
                    Caption = 'SI WB Inbound Job';
                    Editable = false;
                    ToolTip = 'Показує поточний статус Job Queue Entry для codeunit 59052 SI WB Inbound Job.';
                }

                field(SIWBDelayJobLink; JobQueueLinkText)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ShowCaption = false;
                    Editable = false;
                    DrillDown = true;
                    Style = StrongAccent;
                    ToolTip = 'Відкриває Job Queue Entries, відфільтровані за SI WB Inbound Job.';

                    trigger OnDrillDown()
                    begin
                        OpenInboundJobQueueEntry();
                    end;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(OpenWeighbridgeInboundJob)
            {
                ApplicationArea = All;
                Caption = 'Відкрити SI WB Inbound Job';
                Image = Job;
                Visible = IsWeighbridgeCompletedEvent;
                ToolTip = 'Відкриває Job Queue Entries, відфільтровані за codeunit 59052 SI WB Inbound Job.';

                trigger OnAction()
                begin
                    OpenInboundJobQueueEntry();
                end;
            }

            action(RetryWeighbridgeInboundEvent)
            {
                ApplicationArea = All;
                Caption = 'Повторити обробку події';
                Image = Refresh;
                Visible = ShowErrorPanel;
                ToolTip = 'Повертає вибрану помилкову WEIGHING_COMPLETED подію в обробку та запускає її повторно.';

                trigger OnAction()
                var
                    Processor: Codeunit "SI WB Inbound Processor";
                begin
                    Processor.RetrySingleEvent(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }

            action(CleanupWeighbridgeTestData)
            {
                ApplicationArea = All;
                Caption = 'Очистити тестові дані вагової';
                Image = Delete;
                ToolTip = 'Видаляє тестові операційні документи вагової, записи зважувань, evidence та inbound events сервісу WEIGHBRIDGE.';

                trigger OnAction()
                var
                    CleanupMgt: Codeunit "SI WB Test Data Cleanup";
                begin
                    CleanupMgt.CleanupSandboxData();

                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateProcessingDiagnostics();
    end;

    var
        ShowErrorPanel: Boolean;
        ShowDelayPanel: Boolean;
        IsWeighbridgeCompletedEvent: Boolean;
        ErrorTitle: Text[100];
        ErrorEntryNo: Integer;
        ErrorSourceRecordId: Text[100];
        ErrorAttemptCount: Integer;
        ErrorProcessingStartedAt: DateTime;
        ErrorProcessedAt: DateTime;
        LastProcessingError: Text[2048];
        DelayTitle: Text[100];
        DelaySummary: Text[1024];
        PendingCompletedCount: Integer;
        OldestPendingAt: DateTime;
        JobQueueStatusText: Text[250];
        JobQueueLinkText: Text[100];

    local procedure UpdateProcessingDiagnostics()
    var
        DelayDuration: Duration;
    begin
        ClearDiagnosticState();

        IsWeighbridgeCompletedEvent :=
            (Rec."Service Code" = WeighbridgeServiceCode()) and
            (Rec."Event Type" = CompletedEventType());

        // FIRST_WEIGHING_RECORDED and all other event types are deliberately
        // ignored here. A first weighing can legitimately remain Accepted
        // indefinitely and must never be presented as a processing failure.
        if not IsWeighbridgeCompletedEvent then
            exit;

        JobQueueStatusText := GetInboundJobQueueStatus();
        JobQueueLinkText := 'Відкрити SI WB Inbound Job (59052)';

        if Rec.Status = Rec.Status::Error then begin
            ShowErrorPanel := true;
            ErrorTitle := '🔴 ПОМИЛКА ОБРОБКИ ПОДІЇ';
            ErrorEntryNo := Rec."Entry No.";
            ErrorSourceRecordId := CopyStr(Rec."Source Record ID", 1, MaxStrLen(ErrorSourceRecordId));
            ErrorAttemptCount := Rec."Processing Attempt Count";
            ErrorProcessingStartedAt := Rec."Processing Started At";
            ErrorProcessedAt := Rec."Processed At";

            LastProcessingError := CopyStr(Rec.GetLastError(), 1, MaxStrLen(LastProcessingError));
            if LastProcessingError = '' then
                LastProcessingError := 'Для події не збережено текст помилки.';

            exit;
        end;

        if Rec.Status <> Rec.Status::Accepted then
            exit;

        if Rec."Received At" = 0DT then
            exit;

        DelayDuration := CurrentDateTime() - Rec."Received At";
        if DelayDuration <= ProcessingDelayThreshold() then
            exit;

        ShowDelayPanel := true;
        DelayTitle := '⚠ ОБРОБКА ПОДІЇ ЗАТРИМУЄТЬСЯ';
        DelaySummary := StrSubstNo(
            'WEIGHING_COMPLETED перебуває у статусі Accepted більше 3 хвилин. Отримано: %1. Час очікування: %2. Можлива проблема з SI WB Inbound Job.',
            Format(Rec."Received At"),
            Format(DelayDuration));

        LoadAcceptedCompletedBacklog();
    end;

    local procedure ClearDiagnosticState()
    begin
        ShowErrorPanel := false;
        ShowDelayPanel := false;
        IsWeighbridgeCompletedEvent := false;
        Clear(ErrorTitle);
        ErrorEntryNo := 0;
        Clear(ErrorSourceRecordId);
        ErrorAttemptCount := 0;
        ErrorProcessingStartedAt := 0DT;
        ErrorProcessedAt := 0DT;
        Clear(LastProcessingError);
        Clear(DelayTitle);
        Clear(DelaySummary);
        PendingCompletedCount := 0;
        OldestPendingAt := 0DT;
        Clear(JobQueueStatusText);
        Clear(JobQueueLinkText);
    end;

    local procedure LoadAcceptedCompletedBacklog()
    var
        InboundEvent: Record "SI EDS Inbound Event";
    begin
        InboundEvent.Reset();
        InboundEvent.SetRange("Service Code", WeighbridgeServiceCode());
        InboundEvent.SetRange("Event Type", CompletedEventType());
        InboundEvent.SetRange(Status, InboundEvent.Status::Accepted);

        PendingCompletedCount := InboundEvent.Count();

        InboundEvent.SetCurrentKey(Status, "Received At");
        if InboundEvent.FindFirst() then
            OldestPendingAt := InboundEvent."Received At";
    end;

    local procedure GetInboundJobQueueStatus(): Text[250]
    var
        JobQueueEntry: Record "Job Queue Entry";
        MatchingCount: Integer;
    begin
        SetInboundJobQueueFilters(JobQueueEntry);
        MatchingCount := JobQueueEntry.Count();

        if MatchingCount = 0 then
            exit('Не знайдено');

        if not JobQueueEntry.FindFirst() then
            exit('Не знайдено');

        if MatchingCount = 1 then
            exit(Format(JobQueueEntry.Status));

        exit(CopyStr(
            StrSubstNo('%1 (%2 записів)', Format(JobQueueEntry.Status), MatchingCount),
            1,
            250));
    end;

    local procedure OpenInboundJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetInboundJobQueueFilters(JobQueueEntry);

        if JobQueueEntry.IsEmpty() then begin
            Message('Job Queue Entry для codeunit 59052 SI WB Inbound Job не знайдено.');
            exit;
        end;

        Page.Run(Page::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure SetInboundJobQueueFilters(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", InboundJobCodeunitId());
    end;

    local procedure ProcessingDelayThreshold(): Duration
    begin
        // Edge Agent / inbound processing normally cycles every 10 seconds.
        // One minute therefore represents roughly six missed cycles.
        // exit(60 * 1000);
        exit(180 * 1000);
    end;

    local procedure WeighbridgeServiceCode(): Code[50]
    begin
        exit('WEIGHBRIDGE');
    end;

    local procedure CompletedEventType(): Code[50]
    begin
        exit('WEIGHING_COMPLETED');
    end;

    local procedure InboundJobCodeunitId(): Integer
    begin
        exit(59052);
    end;
}
