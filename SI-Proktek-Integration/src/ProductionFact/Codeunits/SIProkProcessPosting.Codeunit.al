codeunit 57144 "SI Prok Process Posting"
{
    // SI Process Production Stage 2. Sandbox-only one-shot posting.
    // BC Item Jnl.-Post Batch performs standard Negative/Positive Adjustment.
    // Durable Started attempt is committed BEFORE standard posting because BC
    // may commit individual journal lines. Never assume atomicity of 7 lines.

    procedure PostSandbox(var Fact: Record "SI Prok Production Fact")
    begin
        PostSandboxInternal(Fact, false);
    end;

    // TEMPORARY FAULT-INJECTION TEST ONLY. Never include in a PROD release.
    // Uses the same posting path, but intentionally fails AFTER the durable
    // Started fence is committed and BEFORE the standard Item Journal posts.
    procedure SimulateFailureAfterCommitSandbox(var Fact: Record "SI Prok Production Fact")
    begin
        PostSandboxInternal(Fact, true);
    end;

    local procedure PostSandboxInternal(var Fact: Record "SI Prok Production Fact"; InjectFailureAfterCommit: Boolean)
    var
        Env: Codeunit "Environment Information";
        Attempt: Record "SI Prok Posting Attempt";
        Control: Codeunit "SI Prok Process Control";
        Cleanup: Codeunit "SI Prok Process Jnl Cleanup";
        CleanupResult: Integer;
        CountLines: Integer;
        Posted: Integer;
        Missing: Integer;
    begin
        if not Env.IsSandbox() then
            Error('SI Process: проведення Stage 2 дозволено лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process: для UUID %1 вже була спроба (%2). Повтор заборонено; використайте аудит/відновлення.',
                Fact."Production UUID", Attempt.Status);
        CountLines := Control.AssertPrepared(Fact);
        if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('SI Process: за документом %1 уже є проведені записи. Повтор заборонено.', Fact."Accounting Document No.");
        if InjectFailureAfterCommit then begin
            if not Confirm('SI Process TEST (Sandbox): імітувати аварію для факту %1, документа %2? Буде збережено Started-спробу, але Item Journal НЕ проводитиметься. Відновлення — окремою дією після 10 хвилин.',
                false, Fact."Entry No.", Fact."Accounting Document No.") then
                exit;
        end else
            if not Confirm('SI Process: провести %1 рядків документа %2 для факту %3 у Sandbox? Будуть змінені реальні залишки Sandbox; повтор автоматично заблоковано.',
                false, CountLines, Fact."Accounting Document No.", Fact."Entry No.") then
                exit;
        // Revalidate after confirmation; acquire the one-shot fence only now.
        Attempt.LockTable();
        if Attempt.Get(Fact."Production UUID") then
            Error('SI Process: спробу вже створено іншим сеансом.');
        Control.AssertPrepared(Fact);
        if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('SI Process: після підтвердження виявлено проведені записи.');
        Attempt.Init();
        Attempt."Production UUID" := Fact."Production UUID";
        Attempt."Fact Entry No." := Fact."Entry No.";
        Attempt.Status := Attempt.Status::Started;
        Attempt."Started At" := CurrentDateTime();
        Attempt.Insert(true);
        Commit(); // Intentional durable one-shot fence. No silent automatic retry.

        // One final read-only validation after the fence, before standard posting.
        Control.AssertPrepared(Fact);
        if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
            Error('SI Process: після створення спроби з’явилися проведені записи. Нове проведення заблоковано.');
        // TEST ONLY: the preceding Commit() makes Started durable even when
        // this Error rolls back the current transaction. No ILE is created.
        if InjectFailureAfterCommit then
            Error('SI Process TEST: збій після Commit() зімітовано. Спроба залишилася Started; журнал НЕ проведено. Виконайте аудит (0 проведено) і дочекайтеся 10 хв перед Recovery.');
        PostPreparedBatch(Fact);
        if Control.LedgerStatus(Fact, Posted, Missing) <> 1 then
            Error('SI Process: стандартне проведення завершилося без повного набору Item Ledger Entries. Спроба залишиться Started; потрібен аудит.');
        MarkCompleted(Fact);
        CleanupResult := Cleanup.CleanupAfterCompleted(Fact);
        if CleanupResult < 0 then
            Message('SI Process: документ %1 проведено (%2 груп), але в пакеті залишилися неідентифіковані рядки. Автоматичне очищення заблоковано; потрібна перевірка.',
                Fact."Accounting Document No.", Posted)
        else
            Message('SI Process: документ %1 проведено стандартним BC. Факт %2; груп записів %3. Очищено технічних рядків: %4.',
                Fact."Accounting Document No.", Fact."Entry No.", Posted, CleanupResult);
    end;

    // Explicit human-authorized recovery. Only two provable states are safe:
    // 0 posted => original journal intact; allow controlled retry after 10 min.
    // 1 posted => mark the already-posted attempt Completed, DO NOT post again.
    // 2 partial => BLOCK, no recreation of lines and no automatic remainder.
    procedure RecoverSandbox(var Fact: Record "SI Prok Production Fact")
    var
        Env: Codeunit "Environment Information";
        Attempt: Record "SI Prok Posting Attempt";
        Control: Codeunit "SI Prok Process Control";
        Cleanup: Codeunit "SI Prok Process Jnl Cleanup";
        CleanupResult: Integer;
        State: Integer;
        Posted: Integer;
        Missing: Integer;
    begin
        if not Env.IsSandbox() then
            Error('SI Process: відновлення Stage 2 дозволено лише в Sandbox.');
        Fact.Get(Fact."Entry No.");
        if not Attempt.Get(Fact."Production UUID") then
            Error('SI Process: немає спроби проведення. Використайте звичайне контрольоване проведення.');
        if (Attempt."Fact Entry No." <> Fact."Entry No.") or (Attempt.Status <> Attempt.Status::Started) then
            Error('SI Process: відновлювати можна лише Started-спробу цього факту.');
        if CurrentDateTime() - Attempt."Started At" < 600000 then
            Error('SI Process: зачекайте щонайменше 10 хвилин і переконайтеся, що попередній сеанс проведення завершився.');
        State := Control.LedgerStatus(Fact, Posted, Missing);
        case State of
            1:
                begin
                    if not Confirm('SI Process: усі записи документа %1 вже проведені. Лише позначити спробу Completed БЕЗ нового проведення?',
                        false, Fact."Accounting Document No.") then
                        exit;
                    Attempt.LockTable();
                    if not Attempt.Get(Fact."Production UUID") then
                        Error('SI Process: спроба зникла під час підтвердження.');
                    if Attempt.Status <> Attempt.Status::Started then
                        Error('SI Process: статус спроби змінився.');
                    if Control.LedgerStatus(Fact, Posted, Missing) <> 1 then
                        Error('SI Process: проведені записи змінилися; повторіть аудит.');
                    MarkCompleted(Fact);
                    CleanupResult := Cleanup.CleanupAfterCompleted(Fact);
                    if CleanupResult < 0 then
                        Message('SI Process: проведення підтверджено без повторних операцій, але залишкові рядки пакета потребують ручної перевірки.')
                    else
                        Message('SI Process: проведення підтверджено без повторних операцій. Очищено технічних рядків: %1.', CleanupResult);
                end;
            0:
                begin
                    Control.AssertPrepared(Fact);
                    if not Confirm('SI Process: у документі %1 немає проведених записів, усі рядки журналу цілі. Повторити проведення в Sandbox?',
                        false, Fact."Accounting Document No.") then
                        exit;
                    // Do not create a new Attempt. Existing Started is the fence.
                    Attempt.LockTable();
                    if not Attempt.Get(Fact."Production UUID") then
                        Error('SI Process: спроба зникла під час підтвердження.');
                    if Attempt.Status <> Attempt.Status::Started then
                        Error('SI Process: статус спроби змінився.');
                    Control.AssertPrepared(Fact);
                    if Control.LedgerStatus(Fact, Posted, Missing) <> 0 then
                        Error('SI Process: стан проведення змінився; відновлення заблоковано.');
                    PostPreparedBatch(Fact);
                    if Control.LedgerStatus(Fact, Posted, Missing) <> 1 then
                        Error('SI Process: після відновлення не всі записи проведені. Виконайте аудит.');
                    MarkCompleted(Fact);
                    CleanupResult := Cleanup.CleanupAfterCompleted(Fact);
                    if CleanupResult < 0 then
                        Message('SI Process: відновлене проведення документа %1 завершено, але залишкові рядки пакета потребують ручної перевірки.', Fact."Accounting Document No.")
                    else
                        Message('SI Process: відновлене проведення документа %1 завершено. Очищено технічних рядків: %2.',
                            Fact."Accounting Document No.", CleanupResult);
                end;
            2:
                Error('SI Process: документ %1 проведено ЧАСТКОВО (%2 груп проведено, %3 відсутні). Автоматичне відновлення заборонено; потрібен ручний розбір.',
                    Fact."Accounting Document No.", Posted, Missing);
        end;
    end;

    local procedure PostPreparedBatch(Fact: Record "SI Prok Production Fact")
    var
        Link: Record "SI Prok Journal Link";
        JournalLine: Record "Item Journal Line";
    begin
        // Resolve the batch from the immutable prepared link, not from mutable
        // setup after the durable Attempt has already been committed.
        Link.SetRange("Fact Entry No.", Fact."Entry No.");
        if not Link.FindFirst() then
            Error('SI Process: відсутні Journal Links перед проведенням факту %1.', Fact."Entry No.");
        JournalLine.SetRange("Journal Template Name", Link."Journal Template");
        JournalLine.SetRange("Journal Batch Name", Link."Journal Batch");
        if not JournalLine.FindFirst() then
            Error('SI Process: пакет %1/%2 порожній перед проведенням факту %3.',
                Link."Journal Template", Link."Journal Batch", Fact."Entry No.");
        // Standard BC posting only; no direct Item Ledger, Value Entry or G/L writes.
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", JournalLine);
    end;

    local procedure MarkCompleted(var Fact: Record "SI Prok Production Fact")
    var
        Attempt: Record "SI Prok Posting Attempt";
    begin
        if not Attempt.Get(Fact."Production UUID") then
            Error('SI Process: немає durable posting attempt для завершення.');
        if (Attempt."Fact Entry No." <> Fact."Entry No.") or (Attempt.Status <> Attempt.Status::Started) then
            Error('SI Process: некоректна спроба проведення для завершення.');
        Attempt.Status := Attempt.Status::Completed;
        Attempt."Finished At" := CurrentDateTime();
        Attempt.Modify(true);
        Fact.Get(Fact."Entry No.");
        Fact."Accounting Diagnostics" := 'SI Process Production: стандартні Negative/Positive Adjustment проведено; перевірено Item Ledger Entries.';
        Fact."Accounting Checked At" := CurrentDateTime();
        Fact.Modify(true);
    end;
}
